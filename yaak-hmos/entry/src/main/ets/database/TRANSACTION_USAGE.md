# Database Transaction Usage Guide

## Correct Transaction Usage

The `BaseRepository.executeInTransaction()` method provides a safe way to execute multiple database operations atomically.

### Method Signature

```typescript
protected async executeInTransaction<T>(
  operation: (transaction: relationalStore.Transaction) => Promise<T>
): Promise<T>
```

### Basic Usage Example

```typescript
// In a Repository class
async deleteMultipleRequests(requestIds: string[]): Promise<void> {
  await this.executeInTransaction(async (transaction) => {
    // Execute multiple SQL statements within the transaction
    for (const id of requestIds) {
      await transaction.execute(
        'DELETE FROM requests WHERE id = ?',
        [id]
      );
      await transaction.execute(
        'DELETE FROM responses WHERE request_id = ?',
        [id]
      );
    }
  });
}
```

### Complex Transaction Example

```typescript
async moveRequestToFolder(requestId: string, newFolderId: string): Promise<void> {
  await this.executeInTransaction(async (transaction) => {
    // Update request folder
    await transaction.execute(
      'UPDATE requests SET folder_id = ?, updated_at = ? WHERE id = ?',
      [newFolderId, Date.now(), requestId]
    );
    
    // Update sort priorities
    await transaction.execute(
      'UPDATE requests SET sort_priority = sort_priority + 1 WHERE folder_id = ?',
      [newFolderId]
    );
    
    // Log the operation
    await transaction.execute(
      'INSERT INTO audit_log (action, entity_id, timestamp) VALUES (?, ?, ?)',
      ['move_request', requestId, Date.now()]
    );
  });
}
```

### Transaction with Return Value

```typescript
async duplicateRequestWithResponses(requestId: string): Promise<string> {
  return await this.executeInTransaction(async (transaction) => {
    const newId = this.generateId('req');
    
    // Copy request
    await transaction.execute(
      'INSERT INTO requests SELECT ?, workspace_id, folder_id, name || " Copy", url, method, body, body_type, ?, ? FROM requests WHERE id = ?',
      [newId, Date.now(), Date.now(), requestId]
    );
    
    // Copy responses
    await transaction.execute(
      'INSERT INTO responses SELECT ?, ?, status_code, status_text, headers, body_path, elapsed_time, size, state, ? FROM responses WHERE request_id = ?',
      [this.generateId('res'), newId, Date.now(), requestId]
    );
    
    return newId;
  });
}
```

## Error Handling

The transaction will automatically:
1. **Commit** if all operations succeed
2. **Rollback** if any operation fails
3. **Throw** a new Error with details for handling by the caller

```typescript
try {
  await this.executeInTransaction(async (transaction) => {
    // Your operations here
  });
  console.log('Transaction completed successfully');
} catch (error) {
  // error is always an Error instance
  const err = error as Error;
  console.error('Transaction failed:', err.message);
  // Handle the error appropriately
}
```

**Important**: In ArkTS, you can only throw Error instances. The transaction method will wrap any caught errors in a new Error object with a descriptive message.

## Best Practices

1. **Keep transactions short**: Only include operations that must be atomic
2. **Avoid external calls**: Don't make HTTP requests or file I/O inside transactions
3. **Use parameterized queries**: Always use `?` placeholders to prevent SQL injection
4. **Handle errors**: Wrap transaction calls in try-catch blocks
5. **Return values**: Use the return value to pass data out of the transaction

## Common Patterns

### Cascade Delete

```typescript
async deleteWorkspaceWithChildren(workspaceId: string): Promise<void> {
  await this.executeInTransaction(async (transaction) => {
    await transaction.execute('DELETE FROM responses WHERE request_id IN (SELECT id FROM requests WHERE workspace_id = ?)', [workspaceId]);
    await transaction.execute('DELETE FROM requests WHERE workspace_id = ?', [workspaceId]);
    await transaction.execute('DELETE FROM folders WHERE workspace_id = ?', [workspaceId]);
    await transaction.execute('DELETE FROM environments WHERE workspace_id = ?', [workspaceId]);
    await transaction.execute('DELETE FROM workspaces WHERE id = ?', [workspaceId]);
  });
}
```

### Batch Insert

```typescript
async importRequests(requests: HttpRequest[]): Promise<void> {
  await this.executeInTransaction(async (transaction) => {
    for (const request of requests) {
      await transaction.execute(
        'INSERT INTO requests (id, workspace_id, name, url, method, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [request.id, request.workspace_id, request.name, request.url, request.method, request.created_at, request.updated_at]
      );
    }
  });
}
```

### Update with Validation

```typescript
async updateRequestWithValidation(requestId: string, newUrl: string): Promise<void> {
  await this.executeInTransaction(async (transaction) => {
    // Check if request exists
    const result = await transaction.execute(
      'SELECT COUNT(*) as count FROM requests WHERE id = ?',
      [requestId]
    );
    
    // Update if exists
    await transaction.execute(
      'UPDATE requests SET url = ?, updated_at = ? WHERE id = ?',
      [newUrl, Date.now(), requestId]
    );
  });
}
```

## Notes

- The transaction object is only valid within the operation callback
- Do not store or use the transaction object outside the callback
- All SQL operations must use the transaction.execute() method
- The transaction will be automatically committed or rolled back

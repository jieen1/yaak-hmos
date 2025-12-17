import { HttpRequest } from '../model/HttpRequest';
import { Workspace } from '../model/Workspace';
import { UUID } from '../common/UUID';

export class Importer {
  /**
   * Imports a basic Curl command.
   * Very simplified regex parser for demonstration.
   */
  public static importCurl(curlCommand: string, workspaceId: string): HttpRequest | null {
    if (!curlCommand.trim().startsWith('curl')) return null;

    const req = new HttpRequest();
    req.id = UUID.randomUUID();
    req.workspace_id = workspaceId;
    req.name = 'Imported Curl';
    req.created_at = Date.now();
    req.updated_at = Date.now();

    // Extract URL
    const urlMatch = curlCommand.match(/'([^']+)'| "([^"]+)"| (\S+)/); // Naive
    // Real implementation needs a proper CLI parser or robust regex
    // For now, let's just create a dummy request to show structure
    
    // Attempt to find URL
    const urlParts = curlCommand.split(' ').filter(p => p.startsWith('http'));
    if (urlParts.length > 0) {
      req.url = urlParts[0].replace(/['"]/g, '');
    }

    // Attempt to find method
    if (curlCommand.includes('-X POST') || curlCommand.includes('--data')) {
      req.method = 'POST';
    }
    
    return req;
  }
}



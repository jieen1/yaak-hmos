import util from '@ohos.util';

export class UUID {
  static randomUUID(): string {
    return util.generateRandomUUID(true);
  }
}



import { WebPlugin } from '@capacitor/core';
import { ApplePayPlugin } from './definitions';

export class ApplePayWeb extends WebPlugin implements ApplePayPlugin {
  constructor() {
    super({
      name: 'ApplePay',
      platforms: ['web'],
    });
  }

  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}

const ApplePay = new ApplePayWeb();

export { ApplePay };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(ApplePay);

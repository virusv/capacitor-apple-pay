import { WebPlugin } from '@capacitor/core';
import { ApplePayPlugin, PaymentRequest, PaymentResponse, CanMakePaymentsNetworks } from './definitions';

export class ApplePayWeb extends WebPlugin implements ApplePayPlugin {
  constructor() {
    super({
      name: 'ApplePay',
      platforms: ['web'],
    });
  }
  canMakePayments(): Promise<{ isPayment: boolean; }> {
    return Promise.resolve({ isPayment: false });
  }
  canMakePaymentsNetworks(options: CanMakePaymentsNetworks): Promise<{ isPayment: boolean }> {
    console.log(options);
    return Promise.resolve({ isPayment: false });
  }
  makePaymentRequest(request: PaymentRequest): Promise<PaymentResponse> {
    console.log(request);
    throw new Error('Method not implemented.');
  }
  completeLastTransaction(options: { status: string; }): Promise<void> {
    console.log(options);
    throw new Error('Method not implemented.');
  }
}

const ApplePay = new ApplePayWeb();

export { ApplePay };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(ApplePay);

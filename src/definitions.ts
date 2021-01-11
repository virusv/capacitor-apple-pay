// @ts-expect-error
declare module '@capacitor/core' {
  interface PluginRegistry {
    ApplePay: ApplePayPlugin;
  }
}

export declare type PaymentNetwork = 'mastercard' | 'visa' | 'amex' | 'quicPay' | 'chinaUnionPay' | 'discover' | 'interac' | 'privateLabel';
export declare type PaymentSummaryItemType = 'pending' | 'final';
export declare type ContactField = 'emailAddress' | 'name' | 'phoneNumber' | 'phoneticName' | 'postalAddress';
export declare type MerchantCapability = 'capability3DS' | 'capabilityCredit' | 'capabilityDebit' | 'capabilityEMV';

export interface PaymentSummaryItem {
  label: string;
  amount: number;
  type?: PaymentSummaryItemType;
}

export interface PersonNameComponents {
  familyName?: string;
  givenName?: string;
  namePrefix?: string;
  middleName?: string;
  nameSuffix?: string;
  nickname?: string;
  phoneticRepresentation?: PersonNameComponents;
}

export interface PaymentContact {
  emailAddress: string;
  phoneNumber?: string;
  name?: PersonNameComponents;
  postalAddress?: {
    street?: string;
    city?: string;
    postalCode?: string;
    country?: string;
    isoCountryCode?: string;
    subAdministrativeArea?: string;
    subLocality?: string;
  }
}

export interface PaymentRequest {
  merchantIdentifier: string;
  countryCode: string;
  currencyCode: string;
  supportedCountries?: string[];
  supportedNetworks?: PaymentNetwork[];
  paymentSummaryItems: PaymentSummaryItem[];
  requiredShippingContactFields: ContactField[];
  requiredBillingContactFields: ContactField[];
  merchantCapabilities?: MerchantCapability[];
  billingContact?: PaymentContact;
  shippingContact?: PaymentContact;
}
export interface PaymentResponse {
  token: {
    paymentData?: string;
    transactionIdentifier: string;
    paymentMethod: {
      displayName?: string;
      secureElementPass?: {
        deviceAccountNumberSuffix: string;
        deviceAccountIdentifier: string;
        primaryAccountIdentifier: string;
        primaryAccountNumberSuffix: string;
        devicePassIdentifier?: string;
        pairedTerminalIdentifier?: string;
      }
    }
  };

  // TODO:
  // shippingContact: ...
}

export interface ApplePayPlugin {
  canMakePayments(): Promise<{ isPayment: boolean }>;
  makePaymentRequest(request: PaymentRequest): Promise<PaymentResponse>;
  completeLastTransaction(options: { status: string }): Promise<void>;
}

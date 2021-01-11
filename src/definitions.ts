declare module '@capacitor/core' {
  interface PluginRegistry {
    ApplePay: ApplePayPlugin;
  }
}

export interface ApplePayPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}

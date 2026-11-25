// jsdom has no EventSource. This stand-in records the streams the app opens, so a test can play the
// API's part and send a notice (see emitPartyEvent in test/utils).
export class FakeEventSource {
  static instances: FakeEventSource[] = [];

  readonly url: string;
  closed = false;
  private listeners = new Map<string, (() => void)[]>();

  constructor(url: string) {
    this.url = url;
    FakeEventSource.instances.push(this);
  }

  static reset() {
    FakeEventSource.instances = [];
  }

  addEventListener(type: string, listener: () => void) {
    this.listeners.set(type, [...(this.listeners.get(type) ?? []), listener]);
  }

  close() {
    this.closed = true;
  }

  emit(type: string) {
    if (this.closed) return;
    this.listeners.get(type)?.forEach((listener) => {
      listener();
    });
  }
}

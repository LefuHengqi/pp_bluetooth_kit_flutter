import { Any, EventSink } from '@ohos/flutter_ohos';

export class PPLefuStreamHandler {
  private event: EventSink | null = null;

  onListen(args: Any, events: EventSink): void {
    this.event = events;
  }

  onCancel(args: Any): void {
    this.event = null;
  }

  success(data: Any): void {
    if (this.event) {
      this.event.success(data);
    }
  }
}
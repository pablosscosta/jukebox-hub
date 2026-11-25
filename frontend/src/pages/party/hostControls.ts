import type { QueueItem } from '../../api/client';

// Only the host gets these; guests see the same jukebox without buttons.
export type HostControls = {
  busy: boolean;
  onSkip: () => void;
  onStart: () => void;
  onRemove: (item: QueueItem) => void;
};

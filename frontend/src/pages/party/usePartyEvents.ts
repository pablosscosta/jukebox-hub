import { useEffect, useEffectEvent } from 'react';
import { partyEventsUrl } from '../../api/client';

type Handlers = { onChange: () => void; onEnded: () => void };

// Follows the party's live notices (SSE). The stream carries no data: on each notice the screen
// reloads what it shows through the API. EventSource reconnects by itself, and "connected" arrives
// again after each reconnection, so a notice missed while the phone was offline is caught up.
export function usePartyEvents(partyId: string, handlers: Handlers) {
  const onChange = useEffectEvent(() => {
    handlers.onChange();
  });
  const onEnded = useEffectEvent(() => {
    handlers.onEnded();
  });

  useEffect(() => {
    const source = new EventSource(partyEventsUrl(partyId));
    const changed = () => {
      onChange();
    };
    source.addEventListener('connected', changed);
    source.addEventListener('queue_changed', changed);
    source.addEventListener('party_ended', () => {
      // Without closing, EventSource would keep reconnecting to a party that is over.
      source.close();
      onEnded();
    });
    return () => {
      source.close();
    };
  }, [partyId]);
}

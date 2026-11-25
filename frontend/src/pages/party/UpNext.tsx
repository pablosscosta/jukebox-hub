import type { QueueItem } from '../../api/client';
import type { HostControls } from './hostControls';
import { TrackInfo } from './TrackInfo';

type Props = { upNext: QueueItem[]; participantId: string; hostControls?: HostControls };

// What comes next. The API sends it already in play order (the fairness rule).
export function UpNext({ upNext, participantId, hostControls }: Props) {
  const addedBy = (item: QueueItem) =>
    item.addedBy.id === participantId ? 'você' : item.addedBy.displayName;

  return (
    <section className="section" aria-labelledby="up-next-title">
      <h3 id="up-next-title">Próximas{upNext.length > 0 && ` · ${String(upNext.length)}`}</h3>
      {upNext.length === 0 ? (
        <p className="hint">A fila está vazia. Busque uma música para começar.</p>
      ) : (
        <ol className="tracks" aria-label="Próximas músicas">
          {upNext.map((item) => (
            <li key={item.id}>
              <TrackInfo track={item} detail={`por ${addedBy(item)}`} />
              {hostControls && (
                <button
                  type="button"
                  className="button-ghost button-small"
                  aria-label={`Remover ${item.title}`}
                  onClick={() => {
                    hostControls.onRemove(item);
                  }}
                  disabled={hostControls.busy}
                >
                  Remover
                </button>
              )}
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}

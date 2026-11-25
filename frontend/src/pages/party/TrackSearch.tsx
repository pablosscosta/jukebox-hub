import { useState } from 'react';
import { ApiError, addToQueue, searchTracks, type Track } from '../../api/client';
import { TrackInfo } from './TrackInfo';

const QUERY_MAX_LENGTH = 100;

type Props = {
  partyId: string;
  token: string;
  queuedTrackIds: Set<string>;
  limitReached: boolean;
  onAdded: () => void;
  // Errors that end the visit (token no longer valid, party over) go up to the page.
  onFatalError: (err: unknown) => boolean;
};

// Searches Spotify (through the API, with the host's account) and adds songs to the queue.
export function TrackSearch({
  partyId,
  token,
  queuedTrackIds,
  limitReached,
  onAdded,
  onFatalError,
}: Props) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Track[] | null>(null);
  const [searching, setSearching] = useState(false);
  const [addingId, setAddingId] = useState<string | null>(null);
  const [message, setMessage] = useState<{ text: string; isError: boolean } | null>(null);

  function showError(err: unknown) {
    if (onFatalError(err)) return;
    const text = err instanceof ApiError ? err.message : 'Algo deu errado. Tente de novo.';
    setMessage({ text, isError: true });
  }

  async function handleSearch() {
    setSearching(true);
    setMessage(null);
    try {
      setResults(await searchTracks(partyId, query.trim(), token));
    } catch (err) {
      showError(err);
    } finally {
      setSearching(false);
    }
  }

  function clearSearch() {
    setQuery('');
    setResults(null);
  }

  async function handleAdd(track: Track) {
    setAddingId(track.trackId);
    setMessage(null);
    try {
      await addToQueue(partyId, track.trackId, token);
      setMessage({ text: `"${track.title}" entrou na fila.`, isError: false });
      // The song is in: clear the search so the queue gets the screen back.
      clearSearch();
      onAdded();
    } catch (err) {
      showError(err);
      // Someone else may have added it, or the queue changed: show the queue as it is now.
      if (err instanceof ApiError && err.status === 409) onAdded();
    } finally {
      setAddingId(null);
    }
  }

  return (
    <section aria-labelledby="search-title">
      <h2 id="search-title">Adicionar música</h2>
      <form
        className="copy-field"
        role="search"
        onSubmit={(event) => {
          event.preventDefault();
          void handleSearch();
        }}
      >
        <input
          aria-label="Buscar música ou artista"
          placeholder="Música ou artista"
          value={query}
          onChange={(event) => {
            setQuery(event.target.value);
          }}
          maxLength={QUERY_MAX_LENGTH}
          required
        />
        <button type="submit" disabled={searching || query.trim() === ''}>
          {searching ? 'Buscando...' : 'Buscar'}
        </button>
        {results && (
          <button
            type="button"
            onClick={() => {
              clearSearch();
              setMessage(null);
            }}
          >
            Limpar
          </button>
        )}
      </form>

      {message && <p role={message.isError ? 'alert' : 'status'}>{message.text}</p>}
      {limitReached && (
        <p className="hint">Você chegou ao limite da fila. Espere uma das suas músicas tocar.</p>
      )}

      {results?.length === 0 && <p>Nenhuma música encontrada.</p>}
      {results && results.length > 0 && (
        <ul className="tracks" aria-label="Resultados da busca">
          {results.map((track) => {
            const queued = queuedTrackIds.has(track.trackId);
            return (
              <li key={track.trackId}>
                <TrackInfo track={track} />
                <button
                  type="button"
                  aria-label={`Adicionar ${track.title}`}
                  disabled={queued || limitReached || addingId !== null}
                  onClick={() => void handleAdd(track)}
                >
                  {queued ? 'Na fila' : addingId === track.trackId ? 'Adicionando...' : 'Adicionar'}
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}

import { useCallback, useEffect, useState } from 'react';
import { ApiError, createParty, getDevices, type Device, type Party } from '../../api/client';

const NAME_MAX_LENGTH = 60;

const DEVICE_TYPES: Record<string, string> = {
  Computer: 'Computador',
  Smartphone: 'Celular',
  Speaker: 'Caixa de som',
  TV: 'TV',
};

type Props = {
  token: string;
  onCreated: (party: Party) => void;
  onUnauthorized: () => void;
};

// Lets the host name the party and pick the Spotify device where the music will play.
export function CreatePartyForm({ token, onCreated, onUnauthorized }: Props) {
  const [devices, setDevices] = useState<Device[] | null>(null);
  const [deviceId, setDeviceId] = useState('');
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const handleError = useCallback(
    (err: unknown) => {
      if (err instanceof ApiError && err.status === 401) {
        onUnauthorized();
        return;
      }
      setError(err instanceof ApiError ? err.message : 'Algo deu errado. Tente de novo.');
    },
    [onUnauthorized],
  );

  // Doesn't clear the error on purpose: after "device unavailable" the list reloads and the
  // message must stay on screen.
  const loadDevices = useCallback(() => {
    getDevices(token)
      .then((list) => {
        setDevices(list);
        // Starts with the device that is already playing, the most likely choice.
        setDeviceId((list.find((device) => device.isActive) ?? list[0])?.id ?? '');
      })
      .catch(handleError);
  }, [token, handleError]);

  useEffect(loadDevices, [loadDevices]);

  function reloadDevices() {
    setError(null);
    loadDevices();
  }

  async function handleSubmit() {
    setSubmitting(true);
    setError(null);
    try {
      onCreated(await createParty(token, { name: name.trim(), deviceId }));
    } catch (err) {
      if (err instanceof ApiError && err.code === 'active_party_exists') {
        // Another tab created a party in the meantime: show that one.
        onCreated((err.body as { party: Party }).party);
        return;
      }
      handleError(err);
      if (err instanceof ApiError && err.code === 'device_unavailable') loadDevices();
    } finally {
      setSubmitting(false);
    }
  }

  if (devices === null) {
    return error ? <p role="alert">{error}</p> : <p className="hint">Procurando seus devices...</p>;
  }

  if (devices.length === 0) {
    return (
      <section>
        {error && <p role="alert">{error}</p>}
        <p>Abra o Spotify no celular ou no computador para ele aparecer aqui.</p>
        <button type="button" onClick={reloadDevices}>
          Recarregar devices
        </button>
      </section>
    );
  }

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault();
        void handleSubmit();
      }}
    >
      <h2>Nova party</h2>
      {error && <p role="alert">{error}</p>}

      <label>
        Nome da party
        <input
          value={name}
          onChange={(event) => {
            setName(event.target.value);
          }}
          maxLength={NAME_MAX_LENGTH}
          placeholder="Churrasco de sábado"
          required
        />
      </label>

      <fieldset>
        <legend>Onde a música vai tocar</legend>
        {devices.map((device) => (
          <label key={device.id} className="device">
            <input
              type="radio"
              name="device"
              value={device.id}
              checked={device.id === deviceId}
              onChange={() => {
                setDeviceId(device.id);
              }}
            />
            {device.name}
            <small>{DEVICE_TYPES[device.type] ?? device.type}</small>
          </label>
        ))}
        <button type="button" className="button-ghost button-small" onClick={reloadDevices}>
          Recarregar devices
        </button>
      </fieldset>

      <button type="submit" className="button-primary" disabled={submitting}>
        {submitting ? 'Criando...' : 'Criar party'}
      </button>
    </form>
  );
}

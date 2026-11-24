import { useState } from 'react';
import type { Party } from '../../api/client';

const timeFormat = new Intl.DateTimeFormat('pt-BR', { hour: '2-digit', minute: '2-digit' });

// The party that is running, with the invite link for the guests.
export function PartyCard({ party }: { party: Party }) {
  const [copyStatus, setCopyStatus] = useState<'idle' | 'copied' | 'failed'>('idle');

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(party.shareUrl);
      setCopyStatus('copied');
    } catch {
      // The browser can block the clipboard; the host can still copy the link by hand.
      setCopyStatus('failed');
    }
  }

  return (
    <section>
      <h2>{party.name}</h2>
      <p>
        Tocando em {party.deviceName} · expira às {timeFormat.format(new Date(party.expiresAt))}
      </p>

      <label>
        Link de convite
        <span className="copy-field">
          <input
            value={party.shareUrl}
            readOnly
            onFocus={(event) => {
              event.target.select();
            }}
          />
          <button type="button" onClick={() => void copyLink()}>
            {copyStatus === 'copied' ? 'Copiado' : 'Copiar'}
          </button>
        </span>
      </label>
      {copyStatus === 'failed' && (
        <p role="alert">Não foi possível copiar. Selecione o link e copie manualmente.</p>
      )}
      <p className="hint">QR code e encerrar party chegam nas próximas partes.</p>
    </section>
  );
}

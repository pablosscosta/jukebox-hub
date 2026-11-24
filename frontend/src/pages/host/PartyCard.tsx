import { QRCodeSVG } from 'qrcode.react';
import { useState } from 'react';
import type { Party } from '../../api/client';

const timeFormat = new Intl.DateTimeFormat('pt-BR', { hour: '2-digit', minute: '2-digit' });

// The party that is running, with the invite link and its QR code for the guests.
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

      {/* Always dark on white with a quiet zone (marginSize), so phone cameras read it in dark mode too. */}
      <QRCodeSVG
        value={party.shareUrl}
        size={200}
        marginSize={2}
        bgColor="#ffffff"
        fgColor="#000000"
        title="QR code do convite"
        role="img"
        className="qr-code"
      />

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
      <p className="hint">Encerrar a party chega numa próxima parte.</p>
    </section>
  );
}

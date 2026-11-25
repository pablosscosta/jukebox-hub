import { QRCodeSVG } from 'qrcode.react';
import { useState } from 'react';
import type { Party } from '../../api/client';

// How guests get in: the QR code to scan and the link to share.
export function InviteCard({ party }: { party: Party }) {
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
    <section id="convite" className="section" aria-labelledby="invite-title">
      <h3 id="invite-title">Convide a galera</h3>
      <div className="card invite">
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

        <label style={{ width: '100%', marginBottom: 0 }}>
          Link de convite
          <span className="copy-field">
            <input
              value={party.shareUrl}
              readOnly
              onFocus={(event) => {
                event.target.select();
              }}
            />
            <button type="button" className="button-small" onClick={() => void copyLink()}>
              {copyStatus === 'copied' ? 'Copiado' : 'Copiar'}
            </button>
          </span>
        </label>
        {copyStatus === 'failed' && (
          <p role="alert">Não foi possível copiar. Selecione o link e copie manualmente.</p>
        )}
      </div>
    </section>
  );
}

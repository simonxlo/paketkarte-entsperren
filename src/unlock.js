// Paketkarte entsperren (inoffiziell)
// Die Live-Zustellkarte wird mit MapLibre und "interactive: false" erzeugt.
// Dieses Skript läuft vor dem Seitencode, erkennt jede neu erzeugte Karte
// und schaltet danach Verschieben, Mausrad- und Doppelklick-Zoom frei.
// Es liest, speichert und sendet keine Daten.
(() => {
  'use strict';

  const KEY = '_interactive'; // wird im MapLibre-Map-Konstruktor per Zuweisung gesetzt

  const isMap = (o) => {
    try {
      return typeof o.getCenter === 'function' &&
        typeof o.getCanvasContainer === 'function' &&
        typeof o.addControl === 'function';
    } catch (e) {
      return false;
    }
  };

  const unlock = (m) => {
    const tryRun = (fn) => { try { fn(); } catch (e) { /* Handler fehlt in dieser Version */ } };
    tryRun(() => m.dragPan.enable());
    tryRun(() => m.scrollZoom.enable());
    tryRun(() => m.doubleClickZoom.enable());
    tryRun(() => m.keyboard.enable());
    tryRun(() => { m.touchZoomRotate.enable(); m.touchZoomRotate.disableRotation(); });
    tryRun(() => { m.setMinZoom(6); m.setMaxZoom(18); });
    tryRun(() => m.getCanvasContainer().classList.add('maplibregl-interactive'));
  };

  Object.defineProperty(Object.prototype, KEY, {
    configurable: true,
    set(value) {
      const map = isMap(this);
      // Wert normal als eigene Eigenschaft ablegen, damit sich nichts anderes ändert.
      Object.defineProperty(this, KEY, { value, writable: true, configurable: true, enumerable: true });
      if (map) {
        const m = this;
        setTimeout(() => unlock(m), 0); // nach dem Konstruktor, wenn alle Handler existieren
      }
    }
  });
})();

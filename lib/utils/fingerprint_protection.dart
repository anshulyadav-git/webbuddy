/// JavaScript injected into every page to defend against fingerprinting.
/// Level-gated: Standard covers the most impactful techniques;
/// Strict adds AudioContext, Battery, Font and Screen spoofing.
class FingerprintProtection {
  /// Standard protection: Canvas + WebGL + Navigator + WebRTC
  static const String standardJs = r'''
(function() {
  if (window._wbFPHooked) return;
  window._wbFPHooked = true;

  // ── Per-load noise seed (changes every page load) ─────────────────────────
  const _seed = Math.floor(Math.random() * 13) + 1;

  // ── 1. Canvas fingerprinting ───────────────────────────────────────────────
  // Adds imperceptible ±1 noise to a single pixel before toDataURL / toBlob.
  (function() {
    const origToDataURL = HTMLCanvasElement.prototype.toDataURL;
    HTMLCanvasElement.prototype.toDataURL = function() {
      _noiseCanvas(this);
      return origToDataURL.apply(this, arguments);
    };
    const origToBlob = HTMLCanvasElement.prototype.toBlob;
    HTMLCanvasElement.prototype.toBlob = function(cb) {
      _noiseCanvas(this);
      return origToBlob.apply(this, arguments);
    };
    const origGetCtx = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function(type) {
      const ctx = origGetCtx.apply(this, arguments);
      if (type === '2d' && ctx && !ctx._wbNoised) {
        ctx._wbNoised = true;
        const origGetImageData = ctx.getImageData.bind(ctx);
        ctx.getImageData = function(x, y, w, h) {
          const d = origGetImageData(x, y, w, h);
          const idx = (_seed * 4) % Math.max(d.data.length - 4, 4);
          d.data[idx] = (d.data[idx] + _seed) % 256;
          return d;
        };
      }
      return ctx;
    };
    function _noiseCanvas(canvas) {
      try {
        const ctx = HTMLCanvasElement.prototype.getContext.call(canvas, '2d');
        if (!ctx) return;
        const x = _seed % Math.max(canvas.width, 1);
        const y = _seed % Math.max(canvas.height, 1);
        const d = ctx.getImageData(x, y, 1, 1);
        d.data[0] = (d.data[0] + _seed) % 256;
        ctx.putImageData(d, x, y);
      } catch(_) {}
    }
  })();

  // ── 2. WebGL fingerprinting ────────────────────────────────────────────────
  (function() {
    const origGetParam = WebGLRenderingContext.prototype.getParameter;
    WebGLRenderingContext.prototype.getParameter = function(param) {
      // UNMASKED_VENDOR_WEBGL = 0x9245, UNMASKED_RENDERER_WEBGL = 0x9246
      if (param === 0x9245) return 'Intel Inc.';
      if (param === 0x9246) return 'Intel Iris OpenGL Engine';
      return origGetParam.apply(this, arguments);
    };
    // WebGL2 as well
    if (window.WebGL2RenderingContext) {
      const orig2 = WebGL2RenderingContext.prototype.getParameter;
      WebGL2RenderingContext.prototype.getParameter = function(param) {
        if (param === 0x9245) return 'Intel Inc.';
        if (param === 0x9246) return 'Intel Iris OpenGL Engine';
        return orig2.apply(this, arguments);
      };
    }
  })();

  // ── 3. Navigator API spoofing ──────────────────────────────────────────────
  (function() {
    try {
      Object.defineProperty(navigator, 'hardwareConcurrency', { get: () => 4 });
      Object.defineProperty(navigator, 'deviceMemory',        { get: () => 8 });
      Object.defineProperty(navigator, 'languages',           { get: () => ['en-US', 'en'] });
      Object.defineProperty(navigator, 'doNotTrack',          { get: () => '1' });
    } catch(_) {}
  })();

  // ── 4. WebRTC IP leak prevention ───────────────────────────────────────────
  (function() {
    const origRTC = window.RTCPeerConnection;
    if (!origRTC) return;
    window.RTCPeerConnection = function(cfg, opt) {
      // Strip STUN/TURN to prevent local IP discovery
      const safeCfg = cfg ? Object.assign({}, cfg, { iceServers: [] }) : {};
      return new origRTC(safeCfg, opt);
    };
    window.RTCPeerConnection.prototype = origRTC.prototype;
    // Also null out deprecated prefixed versions
    ['webkitRTCPeerConnection', 'mozRTCPeerConnection'].forEach(function(k) {
      if (window[k]) window[k] = window.RTCPeerConnection;
    });
  })();

})();
''';

  /// Strict protection: all Standard techniques + AudioContext + Battery + Font + Screen
  static const String strictJs = r'''
(function() {
  if (window._wbFPHookedStrict) return;
  window._wbFPHookedStrict = true;

  // ── 5. AudioContext fingerprinting ────────────────────────────────────────
  (function() {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    const origCreateAnalyser = AC.prototype.createAnalyser;
    AC.prototype.createAnalyser = function() {
      const node = origCreateAnalyser.apply(this, arguments);
      const origGetFloatFreq = node.getFloatFrequencyData.bind(node);
      node.getFloatFrequencyData = function(arr) {
        origGetFloatFreq(arr);
        for (let i = 0; i < arr.length; i++) {
          arr[i] += (Math.random() - 0.5) * 0.0001;
        }
      };
      return node;
    };
    const origCreateBuffer = AC.prototype.createBuffer;
    AC.prototype.createBuffer = function(ch, len, rate) {
      const buf = origCreateBuffer.apply(this, arguments);
      for (let c = 0; c < ch; c++) {
        const data = buf.getChannelData(c);
        for (let i = 0; i < Math.min(data.length, 100); i++) {
          data[i] += (Math.random() - 0.5) * 0.00001;
        }
      }
      return buf;
    };
  })();

  // ── 6. Battery API spoofing ────────────────────────────────────────────────
  if (navigator.getBattery) {
    navigator.getBattery = function() {
      return Promise.resolve({
        charging: true,
        chargingTime: 0,
        dischargingTime: Infinity,
        level: 0.80,
        addEventListener: function() {},
        removeEventListener: function() {},
      });
    };
  }

  // ── 7. Font enumeration blocking ───────────────────────────────────────────
  if (document.fonts && document.fonts.check) {
    const origCheck = document.fonts.check.bind(document.fonts);
    document.fonts.check = function(font, text) {
      // Only return true for system fonts that are universally present
      const safe = ['12px Arial', '12px sans-serif', '12px monospace', '12px serif'];
      if (safe.some(function(s) { return font.indexOf(s.split(' ')[1]) !== -1; })) {
        return origCheck(font, text);
      }
      return false;
    };
  }

  // ── 8. Screen resolution clamping ─────────────────────────────────────────
  (function() {
    try {
      // Report a common phone resolution instead of the real one
      Object.defineProperty(screen, 'width',       { get: () => 390 });
      Object.defineProperty(screen, 'height',      { get: () => 844 });
      Object.defineProperty(screen, 'availWidth',  { get: () => 390 });
      Object.defineProperty(screen, 'availHeight', { get: () => 844 });
      Object.defineProperty(screen, 'colorDepth',  { get: () => 24 });
      Object.defineProperty(screen, 'pixelDepth',  { get: () => 24 });
    } catch(_) {}
  })();

})();
''';
}

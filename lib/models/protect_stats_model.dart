class ProtectStats {
  final int adsBlocked;
  final int trackersBlocked;
  final int fingerprintsBlocked;
  final int httpsUpgrades;

  const ProtectStats({
    this.adsBlocked = 0,
    this.trackersBlocked = 0,
    this.fingerprintsBlocked = 0,
    this.httpsUpgrades = 0,
  });

  int get totalBlocked => adsBlocked + trackersBlocked + fingerprintsBlocked;

  ProtectStats copyWith({
    int? adsBlocked,
    int? trackersBlocked,
    int? fingerprintsBlocked,
    int? httpsUpgrades,
  }) {
    return ProtectStats(
      adsBlocked: adsBlocked ?? this.adsBlocked,
      trackersBlocked: trackersBlocked ?? this.trackersBlocked,
      fingerprintsBlocked: fingerprintsBlocked ?? this.fingerprintsBlocked,
      httpsUpgrades: httpsUpgrades ?? this.httpsUpgrades,
    );
  }
}

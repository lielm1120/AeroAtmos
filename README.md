# AeroAtmos

**International Standard Atmosphere & Density Altitude Calculator for iOS**

AeroAtmos is a professional-grade ISA calculator built for aerospace engineering students, pilots, and aviation enthusiasts. It computes atmospheric properties from sea level to 51 km using the ICAO Standard Atmosphere model (Doc 7488/3).

## Features

### Calculator
- Compute temperature, pressure, density, speed of sound, and viscosity at any altitude (0–51 km)
- Support for geometric and geopotential altitude
- ISA temperature deviation (±50 K)
- Meters and feet unit toggle
- Export/share formatted atmosphere reports

### Atmosphere Profile
- Interactive Swift Charts visualization of all atmospheric properties
- Draggable altitude marker with real-time readout
- Atmosphere layer bands (troposphere through stratopause)

### Density Altitude
- Compute density altitude from pressure altitude and OAT
- Ring gauge visualization with performance impact badges
- Mathematical breakdown of the computation

### ICAO Reference
- Complete ICAO Standard Atmosphere table at 1 km intervals
- Searchable with altitude filter and flight level highlighting
- Full ISA equations reference with expandable sections

### Live Barometer
- Real-time barometric pressure from device sensor (CMAltimeter)
- GPS altitude via CoreLocation
- Automatic ISA comparison with current conditions

## Technical Details

| | |
|---|---|
| **Platform** | iOS 17.0+ |
| **Architecture** | MVVM with @Observable |
| **UI Framework** | SwiftUI + Swift Charts |
| **Sensors** | CoreMotion (CMAltimeter), CoreLocation |
| **Localization** | English, Hebrew |
| **Tests** | 29 unit tests against ICAO reference values |

## Atmosphere Layers Covered

| Layer | Altitude | Lapse Rate |
|---|---|---|
| Troposphere | 0 – 11 km | −6.5 K/km |
| Tropopause | 11 – 20 km | 0 (isothermal) |
| Stratosphere 1 | 20 – 32 km | +1.0 K/km |
| Stratosphere 2 | 32 – 47 km | +2.8 K/km |
| Stratopause | 47 – 51 km | 0 (isothermal) |

## Building

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`.

```bash
# Install XcodeGen (if needed)
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode
open ISACalculator.xcodeproj
```

> **Note:** After running `xcodegen generate`, you may need to restore custom Info.plist keys (UILaunchScreen, CFBundleDisplayName, privacy descriptions) as XcodeGen overwrites the plist.

## Running Tests

```bash
xcodebuild -project ISACalculator.xcodeproj \
  -scheme ISACalculator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test
```

## License

MIT License. See [LICENSE](LICENSE) for details.

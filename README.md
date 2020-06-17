Notificare's Flutter demo app
=============================

Example project on how to implement Notificare's SDK for Flutter.

# Getting started

### Setting up your secrets

You'll need to provide Google Maps API keys for Android and iOS. 

To find out how to get those keys, please visit the according Google documentation at [Getting an API Key for Android](https://developers.google.com/maps/documentation/android-sdk/get-api-key) and [Getting an API Key for iOS](https://developers.google.com/maps/documentation/ios-sdk/get-api-key).

#### Android

On your `local.properties` file under the `android` folder, please add the following keys.

```
app.googleMapsApiKey=your_api_key
```

#### iOS

Create a new file named `Secrets.swift` and paste in the following content.

```
struct Secrets {
    static let googleMapsApiKey = "your_api_key"
}
```

---

Register for a trial:
https://notificare.com/signup

Sign in to the dashboard:
https://dashboard.notifica.re

For documentation please refer to:
https://docs.notifica.re

For support please use:
https://support.notifica.re

## Bloop's gun system 2.0
## A Fast and reliable and heavily optimized gun system styled after site-19

## 🤔 Why?
Instend of using your shitty FE unoptimized gunkit that can crash the server with getgc, use mine! it's better and suites your site!

## ⚡ Optimized Performance
With the help of Packet (Remote event library) the gun system's impact on the game's sent and recive rate remain extremely low even with a filled server!

## 🛡️ GetGC Protection
Protect's the gun system's settings angist the GetGC exploit function. Which is a commonly known exploit to modify tables, functions and in this case modify the settings of the gun to give the exploiter an unfair advantage like infinite ammo!

## 🚀 Easy to setup and use and create custom guns
The gun system only contains 3 Scripts:
* Client Handler - The Client Handler is resposible for handling the player's tools and identifying which tools are weapons and not.
* FirearmClass - An OOP Module (Using metatables) that Inits the firearm and handles userinput, gun effects and more!
* FirearmHandler - The server side script responsible for gun security, GetGC protection, damage handling and informing other clients to create effects.

## 🌠 Features

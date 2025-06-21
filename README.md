# Ping Pong Game for Commodore 64

A classic Pong-style game developed in 6502 assembly language for the Commodore 64. Features include custom sprites, simple CPU opponent, and retro chiptune music powered by GoatTracker.

## Features

- Classic Pong gameplay: Player vs CPU
- Custom sprites for ball and paddles
- SID music (via GoatTracker)
- Runs on real hardware or in emulator (VICE)



## Sprites Used

| Sprite           | Memory Address |
|------------------|---------------|
| Ball             | $3000          |
| Player Paddle    | $3040          |
| CPU Paddle       | $3080          |



## Memory Map

| Purpose      | Address   |
|--------------|-----------|
| Menu Code    | $0810     |
| Game Code    | $2000     |
| Ball Sprite  | $3000     |
| Player Paddle| $3040     |
| CPU Paddle   | $3080     |


## How to Run

1. **Install [CBM PRG Studio](https://www.ajordison.co.uk/)**  
   - Download and install CBM PRG Studio for assembly development.

2. **Configure VICE Emulator**  
   - In CBM PRG Studio: Go to `Settings` > `Emulator` and set the path to your VICE C64 emulator executable (e.g., `x64.exe`).

3. **Load and Build the Project**  
   - Open the project in CBM PRG Studio.
   - Assemble (build) the code.

4. **Run the Game**  
   - Press `F5` or use "Run" to launch the game in VICE.



## Music

Game music is composed in **GoatTracker** and integrated as a SID file.  
To change the music, use GoatTracker, export the SID file, and include it in the assembly.



## Controls

- **Player Paddle:** Use Joystick Port 2 or keyboard (keys may be mapped as W/S or Up/Down arrows, depending on implementation).
- **CPU Paddle:** Controlled by basic AI.



## Credits

- **Programming:** Assembly Language
- **Music:** GoatTracker
- **Sprites:** Open Sprite Resources





Enjoy your retro Ping Pong experience on the Commodore 64!

# chat_server

A simple Erlang OTP chat room application with separate room and user processes.

## Project structure

- `src/` - Erlang OTP source modules
- `include/` - shared header files
- `bin/release.sh` - build script for compiling into `ebin/`

## Requirements

- Erlang/OTP installed
- `erl` and `erlc` available on PATH

## Setup

### Windows

1. Download and install Erlang/OTP from the official website: https://www.erlang.org/downloads
2. During installation, choose the option to add Erlang to `PATH`.
3. Open a new PowerShell or Command Prompt and verify:

```powershell
erl -version
erlc -version
```

### macOS

```bash
brew install erlang
erl -version
erlc -version
```

If you do not use Homebrew, install the Erlang/OTP package from https://www.erlang.org/downloads.

### Linux

For Debian/Ubuntu:

```bash
sudo apt update
sudo apt install erlang
erl -version
erlc -version
```

For other distributions, install Erlang/OTP using the distribution package manager or the official Erlang installer.

## Build

From the repo root, build the application artifacts into the `ebin/` directory:

```bash
./bin/release.sh
```

This will compile all Erlang modules in `src/` and copy the OTP application descriptor into `ebin/`.

## Test

Run unit tests with:

```bash
./bin/test.sh
```

This script builds the project, compiles the EUnit tests, and runs the `chat_room` and `chat_user` test suites.

## Run example

### Server and chat room

Start a chat server in one terminal:

```bash
./bin/start_server.sh
```

Start a room in server's terminal:

```erlang
chat_server_app:create_room(123).
```

### Chat user

Start user "Alice" node in another terminal:

```bash
./bin/start_user.sh Alice
```

Then in the shell:

```erlang
chat_user:join(123).
chat_user:chat("Hello everyone").
```
Start another user "Bob" node in another terminal:

```bash
./bin/start_user.sh Bob
```

Then in the shell:

```erlang
chat_user:join(123).
```
The chat history will be sent to Bob's terminal. Besides, notification that Bob
has joined the room will be sent to Alice.

## Usefull commands

Start a chat server:
```bash
./bin/start_server.sh
```

Start a user:
```bash
./bin/start_user.sh <user_name>
```

Create a room (room Id is 123):
```erlang
chat_server_app:create_room(123).
```

Join a room (room Id is 123):
```erlang
chat_user:join(123).
```

Chat in a room:
```erlang
 chat_user:chat("Hi!").
```

Exit the room:
```erlang
chat_user:exit_room().
```

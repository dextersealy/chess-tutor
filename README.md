# Chess Tutor

Chess Tutor is a single-page web application that teaches you how to play chess. The back-end uses my custom [Ruby on Tracks](https://github.com/dextersealy/ruby-on-tracks) controller/view framework, and the front-end uses plain JavaScript and jQuery.

## Features

TBD

## Implementation

To simplify the back-end, I made it completely stateless. It stores the information about games in progress in the browser session.

The back-eed users a pseudo-[FEN](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) notation to represnet the game. The major difference is ranks are in reverse order.

To implement Undo, the app also stores every move. To avoid exceeding the session limits, it uses a 5-character compact notation for each move.

TDB

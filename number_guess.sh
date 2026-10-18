#!/bin/bash

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Enter your username:"
read -r USERNAME

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
ESCAPED_USERNAME=$(printf "%s" "$USERNAME" | sed "s/'/''/g")
USER_DATA=$($PSQL "SELECT games_played || '|' || best_game FROM users WHERE username='$ESCAPED_USERNAME'")

if [[ -z $USER_DATA ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "Guess the secret number between 1 and 1000:"
while true
do
  read -r GUESS
  ((NUMBER_OF_GUESSES++))

  if [[ ! $GUESS =~ ^-?[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    if [[ $GUESS == -* ]]
    then
      GUESS_NUMBER=$((-10#${GUESS#-}))
    else
      GUESS_NUMBER=$((10#$GUESS))
    fi

    if (( GUESS_NUMBER < SECRET_NUMBER ))
    then
      echo "It's higher than that, guess again:"
    elif (( GUESS_NUMBER > SECRET_NUMBER ))
    then
      echo "It's lower than that, guess again:"
    else
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      if [[ -z $USER_DATA ]]
      then
        $PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$ESCAPED_USERNAME', 1, $NUMBER_OF_GUESSES)" > /dev/null
      else
        $PSQL "UPDATE users SET games_played = games_played + 1, best_game = LEAST(best_game, $NUMBER_OF_GUESSES) WHERE username = '$ESCAPED_USERNAME'" > /dev/null
      fi
      break
    fi
  fi
done
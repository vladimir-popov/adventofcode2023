/*
 * --- Day 2: Cube Conundrum ---
 *
 * You're launched high into the atmosphere! The apex of your trajectory just
 * barely reaches the surface of a large island floating in the sky. You gently
 * land in a fluffy pile of leaves. It's quite cold, but you don't see much
 * snow. An Elf runs over to greet you.
 *
 * The Elf explains that you've arrived at Snow Island and apologizes for the
 * lack of snow. He'll be happy to explain the situation, but it's a bit of a
 * walk, so you have some time. They don't get many visitors up here; would you
 * like to play a game in the meantime?
 *
 * As you walk, the Elf shows you a small bag and some cubes which are either
 * red, green, or blue. Each time you play this game, he will hide a secret
 * number of cubes of each color in the bag, and your goal is to figure out
 * information about the number of cubes.
 *
 * To get information, once a bag has been loaded with cubes, the Elf will
 * reach into the bag, grab a handful of random cubes, show them to you, and
 * then put them back in the bag. He'll do this a few times per game.
 *
 * You play several games and record the information from each game (your
 * puzzle input). Each game is listed with its ID number (like the 11 in Game
 * 11: ...) followed by a semicolon-separated list of subsets of cubes that
 * were revealed from the bag (like 3 red, 5 green, 4 blue).
 *
 * For example, the record of a few games might look like this:
 *
 * Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
 * Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
 * Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
 * Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
 * Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
 *
 * In game 1, three sets of cubes are revealed from the bag (and then put back
 * again). The first set is 3 blue cubes and 4 red cubes; the second set is 1
 * red cube, 2 green cubes, and 6 blue cubes; the third set is only 2 green
 * cubes.
 *
 * The Elf would first like to know which games would have been possible if the
 * bag contained only 12 red cubes, 13 green cubes, and 14 blue cubes?
 *
 * In the example above, games 1, 2, and 5 would have been possible if the bag
 * had been loaded with that configuration. However, game 3 would have been
 * impossible because at one point the Elf showed you 20 red cubes at once;
 * similarly, game 4 would also have been impossible because the Elf showed you
 * 15 blue cubes at once. If you add up the IDs of the games that would have
 * been possible, you get 8.
 *
 * Determine which games would have been possible if the bag had been loaded
 * with only 12 red cubes, 13 green cubes, and 14 blue cubes. What is the sum
 * of the IDs of those games?
 */
#include <stdio.h>
#include <stdlib.h>

typedef struct
{
  long number;
  long blue;
  long red;
  long green;
} game_t;

/**
 * The game is passed if the bag had been loaded
 * with only 12 red cubes, 13 green cubes, and 14 blue cubes.
 */
#define is_game_passed(pgame)                                                 \
  (pgame->red <= 12 && pgame->green <= 13 && pgame->blue <= 14)

/**
 * Example: "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green"
 *
 * return Game ID, or 0 if failed.
 */
int
parse_and_check_game (game_t *restrict game, char **cursor)
{
  // skip "Game"
  *cursor += 4;
  game->number = strtol (*cursor, cursor, 10);
  // skip ":"
  (*cursor)++;

  long number;
  while (**cursor != '\n' && **cursor != '\0')
    {
      switch (**cursor)
        {
        case ',':
        case ' ':
        case '\r':
          break;

        case ';':
          if (!is_game_passed (game))
            return 0;
          game->red = 0;
          game->blue = 0;
          game->green = 0;
          break;
        case 'r':
          *cursor += 2; // [r]ed
          game->red += number;
          break;
        case 'b':
          *cursor += 3; // [b]lue
          game->blue += number;
          break;
        case 'g':
          *cursor += 4; // [g]reen
          game->green += number;
          break;
        default:
          number = strtol (*cursor, cursor, 10);

          if (number == 0)
            return 0;

          break;
        }
      (*cursor)++;
    }
  return is_game_passed (game) ? game->number : 0;
}

int
main (int argc, char *argv[])
{
  /* Getting file name */
  if (argc != 2)
    {
      printf ("You have to specify a file name as the signle argument");
      return EXIT_FAILURE;
    }

  /* Open file to read */
  char *file_name = argv[1];
  FILE *fptr = fopen (file_name, "r");
  if (!fptr)
    {
      printf ("Unable to open file %s", file_name);
      return EXIT_FAILURE;
    }

  /* Read file line by line */
  char *line = NULL;
  size_t len = 0;
  int sum = 0;
  while (getline (&line, &len, fptr) > 0)
    {
      char *cursor = line;
      game_t game = { 0, 0, 0, 0 };
      // clang-format off
      if (parse_and_check_game (&game, &cursor) > 0)
        {
          printf (
            "\033[0;32mPassed game: { num: %ld, red: %ld, blue: %ld, green: %ld }\033[0m\n",
            game.number, game.red, game.blue, game.green
          );
          sum += game.number;
        }
      else
        printf (
            "\033[0;31mNot appropriate game: { num: %ld, red: %ld, blue: %ld, green: %ld }\033[0m\n",
            game.number, game.red, game.blue, game.green
        ); // clang-format on
    }

  /* Close file */
  fclose (fptr);
  /* Free the line buffer */
  free (line);

  /* If we came here, everything is ok */
  printf ("The result is %d", sum);
  return EXIT_SUCCESS;
}

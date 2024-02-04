/*
 * The newly-improved calibration document consists of lines of text;
 * each line originally contained a specific calibration value that
 * the Elves now need to recover. On each line, the calibration value
 * can be found by combining the first digit and the last digit
 * (in that order) to form a single two-digit number.
 *
 * For example:
 *
 * 1abc2
 * pqr3stu8vwx
 * a1b2c3d4e5f
 * treb7uchet
 *
 * In this example, the calibration values of these four lines are
 * 12, 38, 15, and 77. Adding these together produces 142.
 *
 * Consider your entire calibration document. What is the sum of all of
 * the calibration values?
 */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

int
main (int argc, char *argv[])
{
  if (argc != 2)
    {
      printf ("You have to specify a file name as the single argument");
      goto cleanup;
    }

  FILE *fptr = fopen (argv[1], "r");
  if (!fptr)
    {
      printf ("No able to open file %s", argv[1]);
      goto cleanup;
    }

  int c;
  long sum = 0;
  char ns[] = { '\0', '\0', '\0' };
  char *ptr = ns;
  while ((c = fgetc (fptr)) != EOF)
    {
      // is it digit?
      if (isdigit (c))
        {
          *ptr = (char)c;
          ptr = ns + 1;
        }

      // end of line:
      if (c == '\n')
        {
          // duplicate the first digit if the second is absent
          ns[1] = (ns[1] == '\0') ? ns[0] : ns[1];
          sum += strtol (ns, NULL, 10);
          // reset:
          ptr = ns;
          ns[1] = '\0';
        }
    }

  if ((c = ferror (fptr)))
    {
      printf ("IO exception %d", c);
      goto cleanup;
    }

  printf ("The result is: %ld", sum);
  return EXIT_SUCCESS;

cleanup:
  if (fptr)
    fclose (fptr);
  return EXIT_FAILURE;
}

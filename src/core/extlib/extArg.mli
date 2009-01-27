(* 
 * ExtChar - Additional operations on arguments
 * Copyright (C) 1996 Damien Doligez
 *               2009 David Teller, LIFO, Universite d'Orleans
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version,
 * with the special exception on linking described in file LICENSE.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

(** Parsing of command line arguments.

   This module provides a general mechanism for extracting options and
   arguments from the command line to the program.

   Syntax of command lines:
    A keyword is a character string starting with a [-].
    An option is a keyword alone or followed by an argument.
    The types of keywords are: [Unit], [Bool], [Set], [Clear],
    [String], [Set_string], [Int], [Set_int], [Float], [Set_float],
    [Tuple], [Symbol], and [Rest].
    [Unit], [Set] and [Clear] keywords take no argument. A [Rest]
    keyword takes the remaining of the command line as arguments.
    Every other keyword takes the following word on the command line
    as argument.
    Arguments not preceded by a keyword are called anonymous arguments.

   Examples ([cmd] is assumed to be the command name):
-   [cmd -flag           ](a unit option)
-   [cmd -int 1          ](an int option with argument [1])
-   [cmd -string foobar  ](a string option with argument ["foobar"])
-   [cmd -float 12.34    ](a float option with argument [12.34])
-   [cmd a b c           ](three anonymous arguments: ["a"], ["b"], and ["c"])
-   [cmd a b -- c d      ](two anonymous arguments and a rest option with
                           two arguments)

    @author Damien Doligez (Base module)
    @author David Teller

    @documents Arg
*)
module Arg : sig

type spec = Arg.spec =
  | Unit of (unit -> unit)     (** Call the function with unit argument *)
  | Bool of (bool -> unit)     (** Call the function with a bool argument *)
  | Set of bool ref            (** Set the reference to true *)
  | Clear of bool ref          (** Set the reference to false *)
  | String of (string -> unit) (** Call the function with a string argument *)
  | Set_string of string ref   (** Set the reference to the string argument *)
  | Int of (int -> unit)       (** Call the function with an int argument *)
  | Set_int of int ref         (** Set the reference to the int argument *)
  | Float of (float -> unit)   (** Call the function with a float argument *)
  | Set_float of float ref     (** Set the reference to the float argument *)
  | Tuple of spec list         (** Take several arguments according to the
                                   spec list *)
  | Symbol of string list * (string -> unit)
                               (** Take one of the symbols as argument and
                                   call the function with the symbol *)
  | Rest of (string -> unit)   (** Stop interpreting keywords and call the
                                   function with each remaining argument *)
(** The concrete type describing the behavior associated
   with a keyword. *)

type command (**The type describing both the name, documentation and behavior
	  associated with a keyword.*)

exception Help of string
(** Raised by [Arg.parse_argv] when the user asks for help. *)

exception Bad of string
(** Functions in [spec] or [anon_fun] can raise [Arg.Bad] with an error
    message to reject invalid arguments.
    [Arg.Bad] is also raised by [Arg.parse_argv] in case of an error. *)


val command: ?doc:string -> string -> spec -> command
(** Construct a new command, i.e. the specification of a keyword,
    an associated behavior and optionally a usage documentation.

    @param doc A string which will be displayed to the user in
    case of parsing error, and which should explain both the
    behavior and the syntax of this keyword. If left unspecified,
    no documentation is printed.
*)

val handle : ?usage:string -> command list -> string list
(**
   [Arg.handle commands] parses the command-line and applies
   the specifications of [commands] and returns the list
   of anonymous arguments.

   In case of error, the program exits and displays the
   usage message, if specified, and the documentation of
   [command].

   @param usage An optional string which will be displayed to
   the user in case of parsing error. Typically, this string
   should contain the name and version of the program. If
   left unspecified, no usage string is displayed in case of
   error.
*)

(**
   {6 Obsolete interface}
*)


type key = string
type doc = string
type usage_msg = string
type anon_fun = (string -> unit)



val parse :
  (key * spec * doc) list -> anon_fun -> usage_msg -> unit
(** [Arg.parse speclist anon_fun usage_msg] parses the command line.
    [speclist] is a list of triples [(key, spec, doc)].
    [key] is the option keyword, it must start with a ['-'] character.
    [spec] gives the option type and the function to call when this option
    is found on the command line.
    [doc] is a one-line description of this option.
    [anon_fun] is called on anonymous arguments.
    The functions in [spec] and [anon_fun] are called in the same order
    as their arguments appear on the command line.

    If an error occurs, [Arg.parse] exits the program, after printing
    an error message as follows:
-   The reason for the error: unknown option, invalid or missing argument, etc.
-   [usage_msg]
-   The list of options, each followed by the corresponding [doc] string.

    For the user to be able to specify anonymous arguments starting with a
    [-], include for example [("-", String anon_fun, doc)] in [speclist].

    By default, [parse] recognizes two unit options, [-help] and [--help],
    which will display [usage_msg] and the list of options, and exit
    the program.  You can override this behaviour by specifying your
    own [-help] and [--help] options in [speclist].
*)

val parse_argv : ?current: int ref -> string array ->
  (key * spec * doc) list -> anon_fun -> usage_msg -> unit
(** [Arg.parse_argv ~current args speclist anon_fun usage_msg] parses
  the array [args] as if it were the command line.  It uses and updates
  the value of [~current] (if given), or [Arg.current].  You must set
  it before calling [parse_argv].  The initial value of [current]
  is the index of the program name (argument 0) in the array.
  If an error occurs, [Arg.parse_argv] raises [Arg.Bad] with
  the error message as argument.  If option [-help] or [--help] is
  given, [Arg.parse_argv] raises [Arg.Help] with the help message
  as argument.
*)




val usage : (key * spec * doc) list -> usage_msg -> unit
(** [Arg.usage speclist usage_msg] prints an error message including
    the list of valid options.  This is the same message that
    {!Arg.parse} prints in case of error.
    [speclist] and [usage_msg] are the same as for [Arg.parse]. *)

val align: (key * spec * doc) list -> (key * spec * doc) list;;
(** Align the documentation strings by inserting spaces at the first
    space, according to the length of the keyword.  Use a
    space as the first character in a doc string if you want to
    align the whole string.  The doc strings corresponding to
    [Symbol] arguments are not aligned. *)

val current : int ref
(** Position (in {!Sys.argv}) of the argument being processed.  You can
    change this value, e.g. to force {!Arg.parse} to skip some arguments.
    {!Arg.parse} uses the initial value of {!Arg.current} as the index of
    argument 0 (the program name) and starts parsing arguments
    at the next element. *)
end
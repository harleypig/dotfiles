#!/usr/bin/env bats

# Tests for bin/parse_params cross-option constraints: the '%' lines that
# relate two or more option VARNAMEs (exclusive, require-one, together,
# implies). Constraints are judged on what the user actually provided, so a
# default never trips one. A violation is an input error (exit 1); a bad KIND
# or VARNAME is a definition error (exit 2).

load ../helpers/common

setup() {
  load_bats_libs
  PP="$(dotfiles_root)/bin/parse_params"
}

# A definition exercising exclusive + require-one over the same pair (i.e.
# "exactly one of dry_run/force"), plus an unrelated boolean.
excl_def() {
  printf '%s\n' \
    'n|dry-run,boolean,dry_run' \
    'f|force,boolean' \
    'a|all,boolean' \
    '%,exclusive,dry_run,force' \
    '%,require-one,dry_run,force'
}

# --- exclusive --------------------------------------------------------------

@test "exclusive: providing both members fails with 'only one'" {
  run "$PP" "$(excl_def)" -n -f
  assert_failure 1
  assert_output --partial "only one of (--dry-run, --force) may be given"
}

@test "exclusive: one member alone is accepted" {
  run "$PP" "$(excl_def)" --dry-run
  assert_success
  assert_line "dry_run=1"
  assert_line "force=0"
}

@test "exclusive: a negated boolean (--no-force) does not count as active" {
  run "$PP" "$(excl_def)" --dry-run --no-force
  assert_success
  assert_line "dry_run=1"
  assert_line "force=0"
}

@test "exclusive: independent groups are enforced separately" {
  local def
  def=$(printf '%s\n' \
    'a,boolean' 'b,boolean' 'c,boolean' 'd,boolean' \
    '%,exclusive,a,b' '%,exclusive,c,d')

  run "$PP" "$def" -a -c
  assert_success

  run "$PP" "$def" -c -d
  assert_failure 1
  assert_output --partial "only one of (-c, -d) may be given"
}

# --- require-one ------------------------------------------------------------

@test "require-one: providing none of the members fails" {
  run "$PP" "$(excl_def)"
  assert_failure 1
  assert_output --partial "one of (--dry-run, --force) is required"
}

@test "require-one: providing one member satisfies it" {
  run "$PP" "$(excl_def)" -f
  assert_success
  assert_line "force=1"
}

# --- together ---------------------------------------------------------------

@test "together: a partial set (all-or-none) fails" {
  local def
  def=$(printf '%s\n' \
    'u|user,string,user' 'p|pass,string,pass' '%,together,user,pass')

  run "$PP" "$def" --user bob
  assert_failure 1
  assert_output --partial "(--user, --pass) must be given together"
}

@test "together: all members present is accepted" {
  local def
  def=$(printf '%s\n' \
    'u|user,string,user' 'p|pass,string,pass' '%,together,user,pass')

  run "$PP" "$def" --user bob --pass secret
  assert_success
}

@test "together: none present is accepted" {
  local def
  def=$(printf '%s\n' \
    'u|user,string,user' 'p|pass,string,pass' '%,together,user,pass')

  run "$PP" "$def"
  assert_success
}

# --- implies ----------------------------------------------------------------

@test "implies: the antecedent without the consequent fails" {
  local def
  def=$(printf '%s\n' \
    'v|verbose,boolean' 'l|logfile,string,logfile' '%,implies,verbose,logfile')

  run "$PP" "$def" -v
  assert_failure 1
  assert_output --partial "--verbose requires (--logfile)"
}

@test "implies: antecedent with consequent is accepted" {
  local def
  def=$(printf '%s\n' \
    'v|verbose,boolean' 'l|logfile,string,logfile' '%,implies,verbose,logfile')

  run "$PP" "$def" -v -l out.txt
  assert_success
}

@test "implies: neither present is accepted (rule is directional)" {
  local def
  def=$(printf '%s\n' \
    'v|verbose,boolean' 'l|logfile,string,logfile' '%,implies,verbose,logfile')

  run "$PP" "$def"
  assert_success
}

# --- placement & definition errors ------------------------------------------

@test "a constraint line may appear before the options it names" {
  local def
  def=$(printf '%s\n' '%,exclusive,a,b' 'a,boolean' 'b,boolean')

  run "$PP" "$def" -a -b
  assert_failure 1
  assert_output --partial "only one of (-a, -b) may be given"
}

@test "an unknown constraint kind is a definition error (exit 2)" {
  local def
  def=$(printf '%s\n' 'a,boolean' 'b,boolean' '%,bogus,a,b')

  run "$PP" "$def" -a
  assert_failure 2
  assert_output --partial "unknown constraint kind (bogus)"
}

@test "a constraint naming an unknown option is a definition error (exit 2)" {
  local def
  def=$(printf '%s\n' 'a,boolean' 'b,boolean' '%,exclusive,a,zzz')

  run "$PP" "$def" -a
  assert_failure 2
  assert_output --partial "references unknown option (zzz)"
}

@test "a constraint with fewer than two members is a definition error (exit 2)" {
  local def
  def=$(printf '%s\n' 'a,boolean' '%,exclusive,a')

  run "$PP" "$def" -a
  assert_failure 2
  assert_output --partial "needs at least two VARNAMEs"
}

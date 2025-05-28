# vmake-vsh

## Usage

1. Copy the file [vmake.vsh](./vmake.vsh) somewhere in your project directory.

2. Add the rules in the file. There is 3 rules allready that do nothing ('all' 'target' 'fmt') except showing a basic example.

3. Run it `v vmake.vsh <the_rule_to_call> <can_have_multiple_rule_call>`

## Example

```go
// content of the file

@[deps: 'vmake']
fn (r Rules) all(args Args) ! {
}

@[name: 'vmake'; deps: 'vmake.v	v.mod']
fn (r Rules) target(args Args) ! {
	args.sh(@VEXE + ' -prod .')!
}

@[phony]
fn (r Rules) fmt(args Args) ! {
	args.sh(@VEXE + ' fmt -w .')!
}
```

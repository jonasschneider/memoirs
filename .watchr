watch( 'test/.*_test\.rb' )  {|md| c="ruby #{md[0]}"; puts(c); system(c) }

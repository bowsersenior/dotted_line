# DottedLine
require 'dotted_line/signs_on_the_dotted_line'
require 'mongoid'

dir = File.join( File.dirname(__FILE__), 'app', 'models' )

autoload  :RecordChange,  File.join( dir, 'record_change' )
autoload  :Signature,     File.join( dir, 'signature' )

RecordChange
Signature
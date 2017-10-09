/* small.y Version 1.32 */


%{
  char sccsid[] = "@(#)small.y	1.32";

  void yyerror ( const char *s );
  extern "C" int yylex ( );

  #include "small.h"

  bool eol_ok_as_eos = true;
%}

%union { 
    char *string; 
} 

%token	T_GEN T_LINK T_NONE T_ONE T_ME
	T_SET T_DIFFERENCE T_COUNT T_UNION T_INTERSECT T_DISUNION
	T_UNLINK T_GUARD T_CREATE T_DELETE T_SEQ
	T_OR T_AND T_CHAIN T_NAME T_INST_FLOW_OP
        T_STATE T_EOC T_MIGRATE
        T_NEQ T_GEQ T_LEQ T_ITER_SET T_ASCEND T_DESCEND


%token <string>	T_NAME T_TICK_STRING T_BACK_TICK_STRING T_STRING_CONSTANT
		T_ASNR_EVENT_ID T_PROCESS_ID 
		T_WHOLE_CONSTANT T_REAL_CONSTANT T_BOOL_CONSTANT

%type <string> name tick_string event_id relationship_id
	obj_name attribute_name attr_names state_attr
	process_name event_name local_variable
	guard_name_def
	first_object object_exp
	rel_nav_el

%start action 

%%

action		: /* empty */
		| action chain 
		;

chain		: single_chain T_EOC 
		| block T_EOC
		;

single_chain	: unguarded_chain
		| guarded_chain
		;

guarded_chain	: guard   /* empty guard */
		| guard flow
		| guard flow named_seq
		;

unguarded_chain	: /* empty */
		| flow
		| flow named_seq
		| seq flow
		| seq flow named_seq
		;

block		: unguarded_block block_tail
			{ if ( block() ) return 1; }
		| guarded_block block_tail
			{ if ( block() ) return 1; }
		;

unguarded_block	: open_brace 
			{ if ( unguarded_block() ) return 1; }
		| seq open_brace 
			{ if ( unguarded_block() ) return 1; }
		;

block_tail	: action close_brace
		| action close_brace named_seq
		;

guarded_block	: guard open_brace 
			{ if ( guarded_block() ) return 1; }
		;

attribute	: '.' attribute_name
		;

attr_access	: unordered_attr_access ordering
		| unordered_attr_access
		;

unordered_attr_access	: no_order_obj_inst_set attr_list 
		;

attr_list	: attribute
		| attr_name_list
		;
 
attr_name_list	: '.' open_paren attr_names close_paren

attr_names	: attribute_name
		| attr_names data_compose_op attribute_name
			{ $$ = $3; }
		;

create_exp	: datalist create_op obj_name attr_list
		| create_op obj_name
		;

create_exp_no_id : create_exp
		;

data		: value_data
		| attr_access
		;

instance_consumer : link 
		| unlink
		| link_assoc_id
		| link_assoc_no_id
		| unlink_assoc
		| T_NONE check_op guard_def_list
		| gen_event
		;

data_consumer	: transform
		| test
		| gen_event
		| data_merge
		;

data_source	: not_top_level_flow
		| datalist
		| create_exp
		;

data_merge	: data_compose_op datalist
		;

datalist	: data
		| datalist data_compose_op data
		;

instance_source	: obj_inst_set
		| instance_source inst_compose_op obj_inst_set
		;

delete_exp	: obj_inst_set delete_op
		;

flow		: data_flow
		| obj_inst_flow
		;

data_flow	: top_level_flow
		| write_process 
		| delete_exp 
		| migrate_process 
		| gen_event_no_data  /* event to assigner with no data */
		| create_exp_no_id /* not saving created identifier */
		| process_id process_name /* no input parameters, no output data */
		;

obj_inst_flow	: instance_source inst_flow_op instance_consumer
		;

top_level_flow	: flow_exp
		;

not_top_level_flow	: flow_exp
		;

flow_exp	: data_source flow_op data_consumer
		;

gen_event	: T_GEN event_id ':' event_name
		;

gen_event_no_data : gen_event
		;

guard		: T_GUARD guard_usage_list ':'
		;

guard_def_list	: guard_name_def
			{ if ( flow_defined_guard ( $1 ) ) return 1; }
		| guard_def_list guard_op guard_name_def
			{ if ( flow_defined_guard ( $3 ) ) return 1; }
		;

guard_usage_list : guard_name_use
		| guard_usage_list guard_op guard_name_use
		;

obj_var		: name 
		;

obj_set_def 	: name '='
		;

obj_set_use 	: T_ITER_SET name 
		;

link		: T_LINK open_bracket rel_nav_el close_bracket
		;

link_assoc_no_id : link_assoc
		;

link_assoc_id	: link_assoc write_op local_variable
		;

link_assoc	: T_LINK open_bracket rel_nav_el close_bracket create_op obj_name
		;

migrate_process	: obj_inst_set T_MIGRATE obj_name 
		;

named_seq	: seq guard_name_def
			{ if ( seq_defined_guard ( $2 ) ) return 1; }
		;

obj_selection	: obj_name open_paren selector close_paren
		| T_ONE obj_name open_paren selector close_paren
		;
	
first_object	: obj_name open_paren close_paren
		| T_ONE obj_name open_paren close_paren
		| T_ONE open_paren object_exp close_paren
			{ $$ = $3; }
		| T_ME
			{ $$ = "me"; }
		| obj_selection
		| obj_var   
		| obj_set_use
		;

next_object	: relationship_nav obj_name
		| relationship_nav T_ONE obj_name
		| relationship_nav obj_selection
		;

other_objects	: /* empty */ 
		| other_objects next_object
		;

object_exp	: first_object other_objects
		| obj_set_def first_object other_objects
			{ $$ = $2; }
		;

no_order_obj_inst_set : object_exp 
		;

obj_inst_set	: no_order_obj_inst_set ordering
		| no_order_obj_inst_set
		;

ordering	: ordering ordering_el
		| ordering_el
		;

ordering_el	: T_ASCEND name
		| T_DESCEND name
		;

predefined_transform	: T_SET 
		| T_DIFFERENCE 
		| T_COUNT 
		| T_UNION 
		| T_INTERSECT 
		| T_DISUNION
		;

rel_chain	: rel_chain_el
		| rel_chain rel_chain_el
		;

rel_chain_el	: chain_op rel_nav_el
		;

rel_nav_el	: relationship_id
		| relationship_id '.' T_TICK_STRING
		;

relationship_nav : chain_op open_bracket rel_nav_el close_bracket 
		| chain_op open_bracket rel_nav_el rel_chain close_bracket 
		;

relexp		: attribute rel_op value_data
		| open_paren relop_exp close_paren
		;

relop_exp	: conjunction
		| relop_exp disj_op conjunction
		;	

conjunction	: relexp
		| conjunction conj_op relexp
		;

seq		: T_SEQ 
		;

selector	: sel_id_list
		| relop_exp
		;

sel_id_list	: local_variable
		| sel_id_list data_compose_op local_variable
		;

test		: process_id process_name check_op guard_def_list 
		| T_NONE check_op guard_def_list
		;

transform	: process_id process_name
 		| predefined_transform
		;

unlink		: T_UNLINK open_bracket rel_nav_el close_bracket
		;

unlink_assoc	: T_UNLINK open_bracket rel_nav_el close_bracket T_DELETE
		;

value_data	: local_variable | constant | enum
		;

write_process	: data_source write_op local_variable
		| data_source write_op unordered_attr_access
		;

create_op	: T_CREATE
			{ eol_ok_as_eos = false ; }
		;

delete_op	: T_DELETE
			{ eol_ok_as_eos = true; }
		;

close_brace	: '}'
			{ eol_ok_as_eos = true ; }
		;

open_brace	: '{'
			{ eol_ok_as_eos = false ; }
		;

close_bracket	: ']'
			{ eol_ok_as_eos = true ; }
		;

open_bracket	: '['
			{ eol_ok_as_eos = false ; }
		;

conj_op		: T_AND 
			{ eol_ok_as_eos = false ; }
		;

disj_op		: T_OR
			{ eol_ok_as_eos = false ; }
		;

rel_op		: '<' | '>' | '=' | T_NEQ | T_LEQ | T_GEQ
			{ eol_ok_as_eos = false; }
		;

close_paren	: ')'
			{ eol_ok_as_eos = true; }
		;

open_paren	: '('
			{ eol_ok_as_eos = false; }
		;

flow_op		: '|'
			{ eol_ok_as_eos = false; }
		;

inst_flow_op	: T_INST_FLOW_OP
			{ eol_ok_as_eos = false; }
		;

data_compose_op	: '+'
			{ eol_ok_as_eos = false; }
		;

inst_compose_op	: '&'
			{ eol_ok_as_eos = false; }
		;

chain_op	: T_CHAIN 
			{ eol_ok_as_eos = false; }
		;

check_op	: '?'
			{ eol_ok_as_eos = false; }
		;

guard_op	: ','
			{ eol_ok_as_eos = false; }
		;

write_op	: '>'
			{ eol_ok_as_eos = false; }
		;

process_id	: T_PROCESS_ID 
		;

event_id	: T_NAME | T_ASNR_EVENT_ID 
		;

relationship_id	: T_NAME 
		;

name		: T_NAME
			{ eol_ok_as_eos = true; }
		;

tick_string	: T_TICK_STRING
			{ eol_ok_as_eos = true; }
		;

state_attr	: T_STATE
			{ eol_ok_as_eos = true; }
		;
	
obj_name	: name | tick_string
		;

attribute_name	: name | tick_string | state_attr
		;

process_name	: name | tick_string 
		;

event_name	: name | tick_string 
		;

guard_name_use	: name
			{ if ( guard_name_use( $1 ) ) return 1; }
		;
	
guard_name_def	: name 
		;

local_variable	: name ;

constant	: T_STRING_CONSTANT 
		| T_WHOLE_CONSTANT 
		| T_REAL_CONSTANT 
		| T_BOOL_CONSTANT
		;

enum		: T_BACK_TICK_STRING 
		;

%%
#include <stdio.h> 

void yyerror (const char *s ) 
{ 
   extern int yylineno;
   fprintf ( stderr, "%s at line %d\n", s, yylineno ); 
} 

int main ( int argc, char *argv[] )
{
  /* yydebug = 1; */
  if ( argc == 2 )
  {
    if ( strcmp ( argv[1], "-v" ) == 0 )
    {
      puts ( sccsid );
      return 0;
    }
    else
    {
      puts ( "unknown option" );
    }
  }
  action_start();
  int ret_val = yyparse();
  action_end();
  return ret_val;
}

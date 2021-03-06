-- Boost Software License - Version 1.0 - August 17th, 2003 Timo Sarkar, Igel
--
-- Permission is hereby granted, free of charge, to any person or organization
-- obtaining a copy of the software and accompanying documentation covered by
-- this license (the "Software") to use, reproduce, display, distribute,
-- execute, and transmit the Software, and to prepare derivative works of the
-- Software, and to permit third-parties to whom the Software is furnished to
-- do so, all subject to the following:
--
-- The copyright notices in the Software and this entire statement, including
-- the above license grant, this restriction and the following disclaimer,
-- must be included in all copies of the Software, in whole or in part, and
-- all derivative works of the Software, unless such copies or derivative
-- works are solely in the form of machine-executable object code generated by
-- a source language processor.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
-- SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
-- FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
entity core is 
    end entity core;

    library STD;
    use STD.textio.all;
    library WORK;
    use WORK.pkg_readline.all;
    use WORK.types.all;
    use WORK.reader.all;
    use WORk.printer.all;
    use WORK.environment.all;
    use WORK.main.all;

    architecture test of core is

        shared variable repl_env: env_ptr;

        procedure igel_READ( str: in string; ast: out igel_val_ptr; err: out igel_val_ptr ) is
        begin
            read_str( str, ast, err );
        end procedure igel_READ;
        
        procedure starts_with( lst: inout igel_val_ptr; sym: in string; res: out boolean ) is
        begin
            res := lst.seq_val.all'length = 2
                and lst.seq_val.all ( lst.seq_val.all'low ).val_type = igel_symbol
                and lst.seq_val.all ( lst.seq_val.all'low ).string_val.all = sym;
        end starts_with;

        procedure quasiquote( ast: inout igel_val_ptr; result: out igel_val_ptr );

        procedure qq_loop( elt: inout igel_val_ptr; acc: inout igel_val_ptr ) is
            variable sw: boolean := elt.val_type = igel_list;
            variable seq: igel_seq_ptr := new igel_seq( 0 to 2 );
        begin
            if sw then
                starts_with( elt, "splice-unquote", sw );
            end if;

            if sw then
                new_symbol( "concat", seq( 0 ) );
                seq( 1 ) := elt.seq_val( 1 );
            else
                new_symbol( "cons", seq( 0 ) );
                quasiquote( elt, seq( 1 ) );
            end if;

            seq( 2 ) := acc;
            new_seq_obj( igel_list, seq, acc );
        end qq_loop;

        procedure qq_foldr( xs: inout igel_seq_ptr; res: out igel_val_ptr ) is
            variable seq: igel_seq_ptr := new igel_seq( 0 to -1 );
            variable acc: igel_val_ptr;
        begin
            new_seq_obj( igel_list, seq, acc );
            for i in xs'reverse_range loop
                qq_loop( xs( i ), acc );
            end loop;
            res := acc;
        end procedure qq_foldr;

        procedure quasiquote( ast: inout mal_val_ptr; result: out mal_val_ptr) is
            variable sw  : boolean;
            variable seq : mal_seq_ptr;

        begin
            case ast.val_type is
                when igel_list => starts_with( ast, "unquote", sw );
                    if sw then
                        result := ast.seq_val( 1 );
                    else
                        qq_foldr( ast.seq_val, result );
                    end if;
                
                when igel_vector => seq := new igel_seq( 0 to 1 );
                new_symbol( "vec", seq( 0 ) );
                qq_foldr( ast.seq_val, seq( 1 ) );
                new_seq_obj( igel_list, seq, result );
                
                when igel_symbol | igel_hashmap => seq := new igel_seq( 0 to 1 );
                new_symbol( "quote", seq( 0 ) );
                seq( 1 ) := ast;
                new_seq_obj( igel_list, seq, result );
                
                when others => result := ast;
            end case;
        end procedure quasiquote;
    end architecture test;

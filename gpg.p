{us/mf/mfdtitle.i}

define variable lvl_option     as logical        format "Encrypt/Decrypt" 
                                        label "Encrypt/Decrypt"  no-undo.
                                        define variable lvc_path       as character                      no-undo.
define variable lvc_file       as character    format "x(30)"    no-undo.
define variable lvc_cmd        as character                      no-undo.
define variable lvc_rct_mail   as character    format "x(40)"    no-undo.
define variable lvc_passphrase as character    format "x(20)"    no-undo.


form skip(1)
lvl_option     colon 30      skip(1)
lvc_file       colon 30      skip(1)
lvc_rct_mail   colon 30      skip(1)
lvc_passphrase colon 30      skip(1)
with frame a
width 80
side-labels.

/* SET EXTERNAL LABELS */
setFrameLabels(frame a:handle).

/* GET TERM LABELS */
assign
   lvl_option     :label = getTermLabel("GPG_OPTION", 10)
      lvc_rct_mail   :label = getTermLabel("GPG_RCT_MAIL", 15)
         lvc_passphrase :label = getTermLabel("GPG_PASSPHRASE", 21)
            lvc_file       :label = getTermLabel("GPG_FILENAME", 23)
               .

               assign
                 lvc_rct_mail  :help = "Email id of recipient's public key."
                   lvc_passphrase:help = "Keep blank if not set by recipient."
                     lvc_file      :help = 
                         "If decrypting, please enter complete file name along with .gpg extension"
  .

  mainloop:
  repeat:

  clear frame a all.
     
     assign
           lvc_path       = ""
                 lvc_file       = ""
                       lvc_rct_mail   = ""
                             lvc_passphrase = ""
                                   lvl_option     = yes
                                         .
                                            
                                            update 
                                               lvl_option
                                                  lvc_file
                                                     validate(lvc_file <> "", "File name cannot be blank!")
   with frame a.
      
      if lvl_option then
            update
                  lvc_rct_mail
                        validate(lvc_rct_mail <> "", "Recipient email cannot be blank!")
      with frame a.
         
         else 
               update
                     lvc_passphrase
                           with frame a.

                              
   find first code_mstr no-lock 
      where code_mstr.code_domain  = global_domain
           and code_mstr.code_fldname = "gpg_encryption"
                and code_mstr.code_value   = "path".
                   if available code_mstr then 
                         lvc_path = code_mstr.code_cmmt.
                            
                            if lvl_option then 
                                  run gpg_encrypt(input lvc_file, 
                                                        input lvc_rct_mail).
                                                                                              
                                                           else 
                                                                 run gpg_decrypt(input lvc_file, 
                      input lvc_passphrase).               
                      end. /* mainloop */

                      procedure gpg_encrypt:                               
                        define input parameter lvc_file     as character  no-undo.
  define input parameter lvc_rct_mail as character  no-undo.
    
    define variable lvc_encrypted_file  as character  no-undo.
      define variable lvc_line            as character  no-undo.
        
        assign
            lvc_file = lvc_path + lvc_file
                lvc_encrypted_file = trim(lvc_file + ".gpg").
                  
                  lvc_cmd = "gpg --yes --batch --trust-model always --encrypt --recipient " + 
            lvc_rct_mail + " --output " + 
                        lvc_encrypted_file + " " + lvc_file + " 2>/qond/apps/RexelReports/gpg_log.log".
  
  os-command silent value(lvc_cmd).
    

       input from value("/apps/logs/gpg_log.log").
          repeat:
                import unformatted lvc_line.
                   end.
                      input close.  
                        
                        if lvc_line <> "" then do:
                           /* encryption failed */
                               {us/bbi/pxmsg.i
                                         &MSGNUM=77770
                                                   &ERRORLEVEL=1
                                                             }
                                                                end. /* if lvc_line <> "" */
   
   else do:
      /* encryption successful */
            {us/bbi/pxmsg.i
                      &MSGNUM=77771
                                &ERRORLEVEL=1
                                          }
                                             end. /* else */
                                                
                                             end procedure. /* gpg_encrypt */                      

                   procedure gpg_decrypt:                                   
                     define input parameter lvc_file       as character no-undo.                                    
  define input parameter lvc_passphrase as character no-undo.             
    
    define variable lvc_decrypted_file as character no-undo.
      define variable lvc_line           as character no-undo.
        
        assign
            lvc_decrypted_file = lvc_path + trim(replace(lvc_file, ".gpg", ""))
                lvc_file = lvc_path + lvc_file.
                  
                  lvc_cmd = "echo '" + lvc_passphrase + 
                              "' | gpg --batch --passphrase-fd 0 --decrypt --output " +
            lvc_decrypted_file + " " + lvc_file + " 2>/apps/logs/gpg_log.log".
                        
              os-command silent value(lvc_cmd).
                input from value("/apps/logs/gpg_log.log").
                   repeat:
                         import unformatted lvc_line.
                            end.
                               input close.
                                   
                                 if r-index(lvc_line, "failed") <> 0 then do:
                                   /* decryption failed message */
                                       {us/bbi/pxmsg.i
                                                 &MSGNUM=77772
                                                           &ERRORLEVEL=1
                                                                     }
                                                                        end. /* r-index(lvc_line, "failed") <> 0 */
   
   else do:
      /* Successful message */
            {us/bbi/pxmsg.i
                      &MSGNUM=77773
                                &ERRORLEVEL=1
                                          }
                                             end. /* else */
                                                                                                                                            
                                             end procedure. /* gpg_decrypt */
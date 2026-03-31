(defun c:blkparty ( / ss n masterEnt masterVla masterAtts attData tag val slaveEnt slaveVla slaveAtts match i doc )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

  (prompt "\n--- BLKPARTY: EDIÇÃO VISUAL EM MASSA DE BLOCOS ---")
  (prompt "\n1. Selecione os Blocos que deseja alterar simultaneamente: ")
  
  ;; Filtro rigoroso: Só aceita Blocos (INSERT) que possuam Atributos (66 . 1)
  (setq ss (ssget '((0 . "INSERT") (66 . 1))))

  (if ss
    (progn
      (setq n (sslength ss))
      (if (> n 0)
        (progn
          ;; 1. Pega o primeiro bloco selecionado para ser o "Mestre"
          (setq masterEnt (ssname ss 0))

          ;; 2. Abre a janela nativa de edição de atributos (Enhanced Attribute Editor)
          (command "._EATTEDIT" masterEnt)
          
          ;; 3. Pausa a LISP e espera você terminar de editar a janela e clicar em OK
          (while (> (getvar "CMDACTIVE") 0)
            (command "\\")
          )

          (vla-StartUndoMark doc)

          ;; 4. Lê como ficou o Bloco Mestre depois que você fechou a janela
          (setq masterVla (vlax-ename->vla-object masterEnt))
          (setq masterAtts (vlax-invoke masterVla 'GetAttributes))
          (setq attData nil)
          
          ;; Salva uma lista com a TAG e o VALOR (ex: "SITUAÇÃO" -> "EX")
          (foreach att masterAtts
            (setq tag (strcase (vla-get-TagString att)))
            (setq val (vla-get-TextString att))
            (setq attData (cons (cons tag val) attData))
          )

          ;; 5. Injeta as configurações em todos os outros blocos da seleção (Escravos)
          (setq i 1)
          (while (< i n)
            (setq slaveEnt (ssname ss i))
            (setq slaveVla (vlax-ename->vla-object slaveEnt))
            (setq slaveAtts (vlax-invoke slaveVla 'GetAttributes))

            (if slaveAtts
              (foreach sAtt slaveAtts
                (setq tag (strcase (vla-get-TagString sAtt)))
                (setq match (assoc tag attData))
                
                ;; Se a Tag do escravo existir no Mestre, ele clona o valor
                (if match
                  (vl-catch-all-apply 'vla-put-TextString (list sAtt (cdr match)))
                )
              )
            )
            (setq i (1+ i))
          )

          (vla-EndUndoMark doc)
          (princ (strcat "\nFesta Encerrada! " (itoa n) " blocos sincronizados de acordo com as suas edições no bloco mestre!"))
        )
      )
    )
    (princ "\nNenhum Bloco com atributos foi selecionado.")
  )
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
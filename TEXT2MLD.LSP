(defun c:txt2mld ( / ss i ent vla-txt txtStr txtHeight txtColor minPt maxPt p1 p2 ptMidWCS pt1_ucs pt2_ucs mldEnt vla-mld doc )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

  (prompt "\n--- TEXTO PARA MULTILEADER (COR ORIGINAL E ALINHADO A UCS) ---")
  (prompt "\nSelecione os textos (TEXT ou MTEXT) para converter: ")
  (setq ss (ssget '((0 . "TEXT,MTEXT"))))

  (if ss
    (progn
      (setq i 0)
      (vla-StartUndoMark doc)

      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq vla-txt (vlax-ename->vla-object ent))

        ;; 1. Extrai conteúdo, tamanho e cor (ignora a rotação antiga que estava errada!)
        (setq txtStr (vla-get-TextString vla-txt))
        (setq txtHeight (vla-get-Height vla-txt))
        
        ;; Pega a cor exata do texto (com trava de segurança caso a cor seja "ByLayer")
        (setq txtColor (vl-catch-all-apply 'vla-get-TrueColor (list vla-txt)))

        ;; 2. Acha o centro geométrico exato da palavra para cravar a seta
        (vla-GetBoundingBox vla-txt 'minPt 'maxPt)
        (setq p1 (vlax-safearray->list minPt)
              p2 (vlax-safearray->list maxPt))
        (setq ptMidWCS (list (/ (+ (car p1) (car p2)) 2.0)
                             (/ (+ (cadr p1) (cadr p2)) 2.0)
                             (/ (+ (caddr p1) (caddr p2)) 2.0)))

        ;; 3. Converte para a vista atual (UCS)
        (setq pt1_ucs (trans ptMidWCS 0 1)) 
        (setq pt2_ucs (list (+ (car pt1_ucs) (* txtHeight 3.0))
                            (+ (cadr pt1_ucs) (* txtHeight 3.0))
                            0.0))

        (setvar "CMDECHO" 0)

        ;; 4. Desenha a Multileader (O CAD garante que ela nasce alinhada com a tela automaticamente)
        (command "._MLEADER" "_non" pt1_ucs "_non" pt2_ucs txtStr)

        ;; 5. Captura a MLD criada para aplicar a tintura
        (setq mldEnt (entlast))
        (if mldEnt
          (progn
            (setq vla-mld (vlax-ename->vla-object mldEnt))
            
            ;; Se o texto tinha uma cor específica, transfere para a linha e para o texto da MLD
            (if (not (vl-catch-all-error-p txtColor))
              (progn
                (vl-catch-all-apply 'vla-put-TrueColor (list vla-mld txtColor))
                (vl-catch-all-apply 'vla-put-LeaderLineColor (list vla-mld txtColor))
                (vl-catch-all-apply 'vla-put-TextColor (list vla-mld txtColor))
              )
            )

            ;; 6. Apaga o texto de ponta-cabeça antigo
            (vla-Delete vla-txt)
          )
        )

        (setq i (1+ i))
      )
      
      (vla-EndUndoMark doc)
      (setvar "CMDECHO" 1)
      (princ (strcat "\nSucesso! " (itoa i) " textos convertidos. Cores mantidas e texto retinho para a leitura (UCS)!"))
    )
    (princ "\nNenhum texto selecionado.")
  )
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
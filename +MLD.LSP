(defun c:+mld ( / mode ss i ent objType ptList pt p1 p2 minpt maxpt textPt txt mld vlaObj )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  (prompt "\n--- MULTILEADER COM MÚLTIPLAS SETAS ---")

  ;; Pergunta como você quer definir as setas
  (initget "Objetos Pontos")
  (setq mode (getkword "\nComo deseja ancorar as setas? [Selecionar Objetos / Clicar Pontos] <Objetos>: "))
  (if (not mode) (setq mode "Objetos"))

  (setq ptList nil)

  ;; ==========================================================
  ;; MODO 1: SELECIONAR OBJETOS (Cogo Points, Polilinhas, etc)
  ;; ==========================================================
  (if (= mode "Objetos")
    (progn
      (prompt "\n1. Selecione os objetos alvos (Pontos, Cogo Points, Polilinhas...): ")
      (setq ss (ssget))
      (if ss
        (progn
          (setq i 0)
          (while (< i (sslength ss))
            (setq ent (ssname ss i))
            (setq objType (cdr (assoc 0 (entget ent))))
            
            ;; Se for um ponto, pega a coordenada de inserção
            (if (wcmatch objType "POINT,INSERT,AECC_COGO_POINT")
              (setq pt (trans (cdr (assoc 10 (entget ent))) ent 0))
              
              ;; Se for Polilinha ou outro objeto, acha o centro exato dele
              (progn
                (setq vlaObj (vlax-ename->vla-object ent))
                (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-GetBoundingBox (list vlaObj 'minpt 'maxpt))))
                  (progn
                    (setq p1 (vlax-safearray->list minpt))
                    (setq p2 (vlax-safearray->list maxpt))
                    (setq pt (list (/ (+ (car p1) (car p2)) 2.0) (/ (+ (cadr p1) (cadr p2)) 2.0) 0.0))
                  )
                )
              )
            )
            ;; Salva o ponto na nossa lista
            (if pt (setq ptList (cons pt ptList)))
            (setq i (1+ i))
          )
        )
      )
    )
    
  ;; ==========================================================
  ;; MODO 2: CLICAR LIVREMENTE NA TELA
  ;; ==========================================================
    (progn 
      (prompt "\n1. Clique nos locais onde as setas devem apontar.")
      (while (setq pt (getpoint "\nClique no alvo (ou aperte ENTER para concluir): "))
        (setq ptList (cons (trans pt 1 0) ptList))
      )
    )
  )

  ;; ==========================================================
  ;; CRIAÇÃO DA MLEADER UNIFICADA
  ;; ==========================================================
  (if (> (length ptList) 0)
    (progn
      (setq textPt (getpoint "\n2. Clique no local onde ficará a CAIXA DE TEXTO: "))
      (if textPt
        (progn
          (setq txt (getstring T "\n3. Digite o texto da MLeader: "))
          
          (vla-StartUndoMark (vla-get-ActiveDocument (vlax-get-acad-object)))
          (setvar "CMDECHO" 0)
          
          ;; Cria a primeira seta com o texto
          (command "._MLEADER" "_non" (trans (car ptList) 0 1) "_non" textPt txt)
          (setq mld (entlast))

          ;; Se tiver mais de um ponto na lista, adiciona as setas extras no mesmo objeto!
          (if (> (length ptList) 1)
            (progn
              (command "._AIMLEADEREDITADD" mld)
              (foreach p (cdr ptList)
                (command "_non" (trans p 0 1))
              )
              (command "") ;; Encerra a adição de setas
            )
          )
          
          (setvar "CMDECHO" 1)
          (vla-EndUndoMark (vla-get-ActiveDocument (vlax-get-acad-object)))
          (princ (strcat "\nSucesso Total! MLeader criada com " (itoa (length ptList)) " setas apontando para um único texto."))
        )
      )
    )
    (princ "\nComando cancelado. Nenhum alvo foi definido.")
  )
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
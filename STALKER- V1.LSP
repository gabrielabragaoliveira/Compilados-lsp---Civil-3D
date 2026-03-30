(defun c:stalker ( / ss n i ent pos ptList modeSeq modeOri txtInput split-string txtList item wcsPt txt mspace doc textAng mtextObj pt0_dcs ptX_dcs ptY_dcs )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq mspace (vla-get-ModelSpace doc))

  (prompt "\n--- STALKER (BLINDADO PARA VISTAS ROTACIONADAS) ---")
  
  (prompt "\n1. Selecione os PONTOS (AutoCAD Points) que receberão os textos: ")
  (setq ss (ssget '((0 . "POINT"))))
  (if (not ss) (progn (princ "\nNenhum ponto selecionado. Comando cancelado.") (exit)))
  
  (initget "Esquerda Direita Cima Baixo")
  (setq modeSeq (getkword "\n2. Qual o sentido da sequência na TELA? [Esquerda p/ dir / Direita p/ esq / Cima p/ baixo / Baixo p/ cima] <Esquerda>: "))
  (if (not modeSeq) (setq modeSeq "Esquerda"))
  
  (initget "Horizontal Vertical")
  (setq modeOri (getkword "\n3. Sentido de leitura do texto na TELA [Horizontal / Vertical] <Horizontal>: "))
  (if (not modeOri) (setq modeOri "Horizontal"))

  (setq txtInput (getstring T "\n4. Digite a sequência separada por ';' (Ex: 188+891; 188+851; 188+831): "))
  (if (or (= txtInput "") (= txtInput nil)) (progn (princ "\nNenhum texto inserido. Comando cancelado.") (exit)))

  (defun split-string (str delim / pos lst)
    (while (setq pos (vl-string-search delim str))
      (setq lst (cons (substr str 1 pos) lst))
      (setq str (substr str (+ pos 2)))
    )
    (setq lst (cons str lst))
    (reverse lst)
  )

  (setq txtList (split-string txtInput ";"))
  
  (setq n (sslength ss) i 0 ptList nil)
  
  (while (< i n)
    (setq ent (ssname ss i))
    ;; Pega a coordenada no mundo real (WCS)
    (setq pos (trans (cdr (assoc 10 (entget ent))) ent 0)) 
    
    ;; A MÁGICA: Converte o ponto para DCS (A tela física do seu monitor)
    ;; Isso garante que a LISP "enxergue" os pontos exatamente como você está vendo
    (setq ptList (cons (list (trans pos 0 2) pos) ptList)) 
    (setq i (1+ i))
  )
  
  ;; Ordena os pontos baseado exclusivamente no que aparece na sua tela!
  (cond
    ((= modeSeq "Esquerda")
      (setq ptList (vl-sort ptList '(lambda (a b) (< (car (car a)) (car (car b))))))
    )
    ((= modeSeq "Direita")
      (setq ptList (vl-sort ptList '(lambda (a b) (> (car (car a)) (car (car b))))))
    )
    ((= modeSeq "Baixo")
      (setq ptList (vl-sort ptList '(lambda (a b) (< (cadr (car a)) (cadr (car b))))))
    )
    ((= modeSeq "Cima")
      (setq ptList (vl-sort ptList '(lambda (a b) (> (cadr (car a)) (cadr (car b))))))
    )
  )

  ;; ==========================================================
  ;; CALIBRAÇÃO DA TELA (Textos legíveis sem dor de cabeça)
  ;; ==========================================================
  ;; Puxa os eixos do seu monitor (Independente de UCS, DVIEW, ViewCube)
  (setq pt0_dcs (trans '(0 0 0) 2 0))
  (setq ptX_dcs (trans '(1 0 0) 2 0))
  (setq ptY_dcs (trans '(0 1 0) 2 0))
  
  (if (= modeOri "Horizontal")
    (setq textAng (angle pt0_dcs ptX_dcs)) ; Crava na horizontal perfeita do seu monitor
    (setq textAng (angle pt0_dcs ptY_dcs)) ; Crava na vertical perfeita lendo de baixo pra cima
  )

  (vla-StartUndoMark doc)
  
  (setq i 0)
  (while (and (< i (length ptList)) (< i (length txtList)))
    (setq item (nth i ptList))
    (setq wcsPt (cadr item))
    (setq txt (vl-string-trim " \t\n\r" (nth i txtList))) 
    
    (setq mtextObj (vla-AddMText mspace (vlax-3d-point wcsPt) 0.0 txt))
    
    (vla-put-AttachmentPoint mtextObj 5) 
    (vla-put-InsertionPoint mtextObj (vlax-3d-point wcsPt))
    (vla-put-Height mtextObj (getvar "TEXTSIZE"))
    
    ;; Aplica a rotação da tela calibrada
    (vla-put-Rotation mtextObj textAng)
    
    (setq i (1+ i))
  )
  
  (vla-EndUndoMark doc)
  
  (if (> (length ptList) (length txtList))
    (princ (strcat "\nAviso: Faltaram textos! Foram inseridos " (itoa (length txtList)) " textos, mas selecionou " (itoa (length ptList)) " pontos."))
  )
  (if (< (length ptList) (length txtList))
    (princ (strcat "\nAviso: Sobraram textos! Foram inseridos " (itoa (length ptList)) " textos, mas apenas selecionou " (itoa (length txtList)) " pontos."))
  )
  (if (= (length ptList) (length txtList))
    (princ (strcat "\nSucesso Total! " (itoa i) " textos inseridos. Imunes a vistas rotacionadas!"))
  )
  
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
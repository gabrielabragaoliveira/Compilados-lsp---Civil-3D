(defun c:find2me ( / searchStr ss n i ent vlaObj txtStr pt zoomH kwd matchList total current target )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  (prompt "\n--- FIND2ME: O RADAR DE TEXTOS (COM NAVEGAÇÃO) ---")
  
  (setq searchStr (getstring T "\nDigite o texto que deseja buscar: "))
  (if (or (= searchStr "") (= searchStr nil)) (progn (princ "\nBusca cancelada.") (exit)))
  (setq searchStr (strcase searchStr))
  
  (setq ss (ssget "X" '((0 . "TEXT,MTEXT"))))
  (setq matchList '()) ; Lista vazia para guardar os resultados
  
  (if ss
    (progn
      (setq n (sslength ss) i 0)
      (setvar "CMDECHO" 0)
      
      ;; ==========================================================
      ;; FASE 1: ESCANEIA O DESENHO E GUARDA OS ALVOS
      ;; ==========================================================
      (while (< i n)
        (setq ent (ssname ss i))
        (setq vlaObj (vlax-ename->vla-object ent))
        (setq txtStr (vl-catch-all-apply 'vlax-get-property (list vlaObj 'TextString)))
        
        (if (not (vl-catch-all-error-p txtStr))
          (progn
            (if (vl-string-search searchStr (strcase txtStr))
              (setq matchList (cons ent matchList)) ; Adiciona o alvo na lista
            )
          )
        )
        (setq i (1+ i))
      )
      
      ;; Coloca a lista na ordem em que foram criados no AutoCAD
      (setq matchList (reverse matchList))
      (setq total (length matchList))
      
      ;; ==========================================================
      ;; FASE 2: O NAVEGADOR (Pular para frente e para trás)
      ;; ==========================================================
      (if (> total 0)
        (progn
          (setq current 0)
          
          ;; Loop de navegação infinita
          (while (and (>= current 0) (< current total))
            (setq target (nth current matchList))
            (setq vlaObj (vlax-ename->vla-object target))
            
            (setq pt (vlax-safearray->list (vlax-variant-value (vlax-get-property vlaObj 'InsertionPoint))))
            (setq zoomH (* (vlax-get-property vlaObj 'Height) 25.0)) 
            
            (command "._ZOOM" "_C" pt zoomH)
            (redraw target 3) ; Acende a luz no objeto
            
            (initget "Proximo Voltar Sair")
            (setq kwd (getkword (strcat "\n[ Resultado " (itoa (1+ current)) " de " (itoa total) " ] [Proximo / Voltar / Sair] <Proximo>: ")))
            
            (redraw target 4) ; Apaga a luz do objeto
            
            (cond
              ;; Se apertar Enter ou P, vai para o próximo
              ((or (= kwd "Proximo") (= kwd nil)) 
                (setq current (1+ current))
                (if (= current total) (setq current 0)) ; Volta pro começo se passar do limite
              )
              ;; Se digitar V (Voltar), retrocede na lista
              ((= kwd "Voltar") 
                (setq current (1- current))
                (if (< current 0) (setq current (1- total))) ; Vai pro final se retroceder do primeiro
              )
              ;; Se digitar S, encerra o comando
              ((= kwd "Sair") 
                (setq current total) 
              )
            )
          )
          (setvar "CMDECHO" 1)
          (princ "\nNavegação finalizada!")
        )
        (princ (strcat "\nPoxa... Não encontrei nenhum texto contendo '" searchStr "' no desenho."))
      )
    )
    (princ "\nNão existe nenhum texto neste desenho para caçar.")
  )
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
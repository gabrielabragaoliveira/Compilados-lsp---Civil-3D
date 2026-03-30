(defun c:galera ( / sel baseEnt baseVla desc allPts matchSs count i ent vlaEnt ptDesc )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  
  ;; Pede para selecionar o COGO Point de referência (o 'líder' da Galera)
  (setq sel (entsel "\nSelecione o COGO Point de referência (o 'líder' da Galera): "))
  
  (if sel
    (progn
      (setq baseEnt (car sel))
      
      ;; Verifica se você realmente clicou num COGO Point
      (if (= (cdr (assoc 0 (entget baseEnt))) "AECC_COGO_POINT")
        (progn
          (setq baseVla (vlax-ename->vla-object baseEnt))
          
          ;; Tenta pegar a descrição e blinda contra valores nulos
          (setq desc (vl-catch-all-apply 'vlax-get (list baseVla 'RawDescription)))
          (if (or (vl-catch-all-error-p desc) (= desc nil))
            (setq desc "")
            (setq desc (vl-princ-to-string desc))
          )
          
          (prompt (strcat "\nBuscando a galera com a descrição: '" desc "'... aguarde."))
          
          ;; Seleciona TODOS os COGO Points do desenho para filtrar
          (setq allPts (ssget "_X" '((0 . "AECC_COGO_POINT"))))
          (setq matchSs (ssadd))
          (setq count 0)
          
          (if allPts
            (progn
              (setq i 0)
              ;; Faz o loop verificando a descrição de cada ponto
              (while (< i (sslength allPts))
                (setq ent (ssname allPts i))
                (setq vlaEnt (vlax-ename->vla-object ent))
                
                (setq ptDesc (vl-catch-all-apply 'vlax-get (list vlaEnt 'RawDescription)))
                (if (or (vl-catch-all-error-p ptDesc) (= ptDesc nil))
                  (setq ptDesc "")
                  (setq ptDesc (vl-princ-to-string ptDesc))
                )
                
                ;; Se a descrição for idêntica, adiciona na nossa seleção
                (if (= (strcase ptDesc) (strcase desc))
                  (progn
                    (ssadd ent matchSs)
                    (setq count (1+ count))
                  )
                )
                (setq i (1+ i))
              )
              
              ;; Deixa os pontos destacados/selecionados na tela
              (if (> count 0)
                (progn
                  (sssetfirst nil matchSs)
                  (princ (strcat "\nPronto! " (itoa count) " COGO Points da galera '" desc "' foram selecionados!"))
                )
                (princ "\nNenhum outro ponto encontrado com essa descrição.")
              )
            )
          )
        )
        (princ "\nO objeto selecionado não é um COGO Point. Tente de novo!")
      )
    )
    (princ "\nComando cancelado.")
  )
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
(defun c:areatin ( / ent vla-surf stats area2d area3d str2d str3d txtStr pt wcsPt ucsBaseAng doc mspace mtextObj )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  (prompt "\n--- EXTRAÇÃO DE ÁREA 2D E 3D DA SUPERFÍCIE ---")

  ;; 1. Seleção da Superfície
  (setq ent (car (entsel "\n1. Selecione a Superfície (TIN Surface): ")))

  (if (and ent (= (cdr (assoc 0 (entget ent))) "AECC_TIN_SURFACE"))
    (progn
      (setq vla-surf (vlax-ename->vla-object ent))

      ;; Tenta acessar as estatísticas blindando contra erros fatais
      (setq stats (vl-catch-all-apply 'vlax-get-property (list vla-surf 'Statistics)))

      (if (or (vl-catch-all-error-p stats) (not stats))
        (princ "\nErro: O Civil 3D bloqueou a leitura das estatísticas dessa superfície.")
        (progn
          ;; Extrai os valores das áreas
          (setq area2d (vlax-get-property stats 'Area2D))
          (setq area3d (vlax-get-property stats 'Area3D))

          ;; Formatação para o padrão brasileiro (vírgula e 2 casas decimais)
          (setq str2d (vl-string-translate "." "," (rtos area2d 2 2)))
          (setq str3d (vl-string-translate "." "," (rtos area3d 2 2)))

          ;; Monta a caixa de texto
          (setq txtStr (strcat "Área 2D: " str2d " m\\U+00B2\\PÁrea 3D: " str3d " m\\U+00B2"))

          ;; 2. Pede para você escolher o local exato do texto (Evita o erro do Bounding Box)
          (setq pt (getpoint "\n2. Clique no local onde deseja inserir o texto: "))
          
          (if pt
            (progn
              ;; Zera a cota Z para o texto não sumir no espaço 3D
              (setq pt (list (car pt) (cadr pt) 0.0))
              (setq wcsPt (trans pt 1 0))

              ;; Trava de leitura legível acompanhando o UCS
              (setq ucsBaseAng (angle '(0 0 0) (trans '(1 0 0) 1 0)))
              (if (and (> ucsBaseAng (/ pi 2)) (<= ucsBaseAng (* pi 1.5)))
                (setq ucsBaseAng (- ucsBaseAng pi))
              )

              ;; Insere o texto
              (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
              (setq mspace (vla-get-ModelSpace doc))
              (setq mtextObj (vla-AddMText mspace (vlax-3d-point wcsPt) 0.0 txtStr))

              (vla-put-AttachmentPoint mtextObj 5) 
              (vla-put-InsertionPoint mtextObj (vlax-3d-point wcsPt))
              (vla-put-Rotation mtextObj ucsBaseAng)
              (vla-put-Height mtextObj (getvar "TEXTSIZE"))

              (princ "\nSucesso! Áreas anotadas com sucesso na sua prancha.")
            )
            (princ "\nPonto de inserção cancelado.")
          )
        )
      )
    )
    (princ "\nErro: O objeto selecionado não é uma Superfície (TIN Surface) válida.")
  )
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
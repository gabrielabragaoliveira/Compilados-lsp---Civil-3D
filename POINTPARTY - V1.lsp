(defun c:pointparty ( / mode ss i ent vla-ent pos ptList ptNum lower upper hull cross-product pt-ucs ptListLeft ptListRight p1 p2 maxDist d vx vy len nx ny dotLong dotLat avgLat ptProjList sumLat dx dy )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  
  ;; Agora temos 3 botões de opção!
  (initget "Ordem Silhueta Paralelas")
  (setq mode (getkword "\nPointParty! Escolha o modo [Ordem numérica / Silhueta / Paralelas] <Ordem>: "))
  (if (not mode) (setq mode "Ordem")) 
  
  (prompt (strcat "\nModo >> " mode " << ativado. Selecione os COGO Points: "))
  (setq ss (ssget '((0 . "AECC_COGO_POINT"))))
  
  (if ss
    (progn
      (setq i 0 ptList nil)
      
      ;; Loop para extrair as coordenadas
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq vla-ent (vlax-ename->vla-object ent))
        (setq pos (vlax-get vla-ent 'Location))
        
        ;; O SEGREDO DO UCS: Converte a coordenada Global (0) para a coordenada da Tela (1)
        (setq pt-ucs (trans pos 0 1))
        
        (if (= mode "Ordem")
          (progn
            (setq ptNum (vlax-get vla-ent 'Number))
            (setq ptList (cons (list ptNum (list (car pt-ucs) (cadr pt-ucs))) ptList))
          )
          (progn
            (setq ptList (cons (list (car pt-ucs) (cadr pt-ucs)) ptList))
          )
        )
        (setq i (1+ i))
      )
      
      (setvar "CMDECHO" 0)
      
      (cond
        ;; ==========================================
        ;; LÓGICA 1: Ligação por Ordem Numérica
        ;; ==========================================
        ((= mode "Ordem")
          (setq ptList (vl-sort ptList '(lambda (a b) (< (car a) (car b)))))
          (command "._PLINE")
          (foreach item ptList
            (command "_non" (cadr item)) ; "_non" desliga o Osnap para não grudar errado
          )
          (command "") 
          (princ (strcat "\nFesta na Ordem: Polyline criada conectando " (itoa i) " pontos!"))
        )
        
        ;; ==========================================
        ;; LÓGICA 2: Contorno de Silhueta
        ;; ==========================================
        ((= mode "Silhueta")
          (if (>= (length ptList) 3)
            (progn
              (defun cross-product (o a b)
                (- (* (- (car a) (car o)) (- (cadr b) (cadr o)))
                   (* (- (cadr a) (cadr o)) (- (car b) (car o)))
                )
              )
              
              (setq ptList (vl-sort ptList
                '(lambda (p1 p2)
                   (if (equal (car p1) (car p2) 1e-4)
                       (< (cadr p1) (cadr p2))
                       (< (car p1) (car p2))
                   )
                 )
              ))
              
              (setq lower nil)
              (foreach p ptList
                (while (and (>= (length lower) 2)
                            (< (cross-product (cadr lower) (car lower) p) -1e-4))
                  (setq lower (cdr lower))
                )
                (setq lower (cons p lower))
              )
              
              (setq upper nil)
              (setq ptList (reverse ptList))
              (foreach p ptList
                (while (and (>= (length upper) 2)
                            (< (cross-product (cadr upper) (car upper) p) -1e-4))
                  (setq upper (cdr upper))
                )
                (setq upper (cons p upper))
              )
              
              (setq hull (append (reverse (cdr lower)) (reverse (cdr upper))))
              
              (command "._PLINE")
              (foreach pt hull
                (command "_non" pt)
              )
              (command "_C")
              (princ "\nFesta na Silhueta: Contorno extremo fechado com sucesso!")
            )
            (princ "\nSão necessários pelo menos 3 COGO Points para criar uma silhueta.")
          )
        )
        
        ;; ==========================================
        ;; LÓGICA 3: Duas Linhas Paralelas
        ;; ==========================================
        ((= mode "Paralelas")
          (if (>= (length ptList) 4)
            (progn
              ;; 1. Acha os dois pontos mais distantes para definir o "eixo" da rua
              (setq maxDist -1.0 p1 nil p2 nil)
              (foreach a ptList
                (foreach b ptList
                  (setq d (distance a b))
                  (if (> d maxDist)
                    (setq maxDist d p1 a p2 b)
                  )
                )
              )
              
              ;; 2. Geometria do vetor principal
              (setq vx (- (car p2) (car p1)))
              (setq vy (- (cadr p2) (cadr p1)))
              (setq len (distance p1 p2))
              (setq nx (/ (- vy) len))
              (setq ny (/ vx len))
              
              ;; 3. Calcula de que lado cada ponto está
              (setq ptProjList nil sumLat 0.0)
              (foreach p ptList
                (setq dx (- (car p) (car p1)))
                (setq dy (- (cadr p) (cadr p1)))
                (setq dotLong (+ (* dx (/ vx len)) (* dy (/ vy len)))) ; Distância ao longo da rua
                (setq dotLat (+ (* dx nx) (* dy ny)))                  ; Distância lateral (esq/dir)
                
                (setq ptProjList (cons (list p dotLong dotLat) ptProjList))
                (setq sumLat (+ sumLat dotLat))
              )
              
              (setq avgLat (/ sumLat (length ptList)))
              
              ;; 4. Separa a galera da Esquerda e da Direita
              (setq ptListLeft nil ptListRight nil)
              (foreach item ptProjList
                (if (> (caddr item) avgLat)
                  (setq ptListLeft (cons item ptListLeft))
                  (setq ptListRight (cons item ptListRight))
                )
              )
              
              ;; 5. Ordena os pontos de cada lado do começo ao fim da rua
              (setq ptListLeft (vl-sort ptListLeft '(lambda (a b) (< (cadr a) (cadr b)))))
              (setq ptListRight (vl-sort ptListRight '(lambda (a b) (< (cadr a) (cadr b)))))
              
              ;; 6. Desenha as duas Polilinhas independentes!
              (if (>= (length ptListLeft) 2)
                (progn
                  (command "._PLINE")
                  (foreach item ptListLeft (command "_non" (car item)))
                  (command "")
                )
              )
              (if (>= (length ptListRight) 2)
                (progn
                  (command "._PLINE")
                  (foreach item ptListRight (command "_non" (car item)))
                  (command "")
                )
              )
              
              (princ "\nFesta Paralela: Duas polilinhas independentes desenhadas com sucesso!")
            )
            (princ "\nSão necessários pelo menos 4 pontos para detectar um alinhamento paralelo.")
          )
        )
      )
      (setvar "CMDECHO" 1)
    )
    (princ "\nNenhum COGO Point selecionado.")
  )
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
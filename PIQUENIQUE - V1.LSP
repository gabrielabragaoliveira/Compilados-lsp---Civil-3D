(defun c:piquenique ( / ss i ent vla-ent pos desc sumX sumY sumZ n ptCentroWCS ptCentroUCS ptUCS px py minX maxX minY maxY boxW boxH len maxH_W maxH_H idealHeight )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  
  (prompt "\n--- PIQUENIQUE (AUTO-ESCALA) ---")
  (prompt "\nSelecione os COGO Points de uma forma para rotular (Prima ESC para sair).")
  
  (while (setq ss (ssget '((0 . "AECC_COGO_POINT"))))
    (setq n (sslength ss))
    (setq sumX 0.0 sumY 0.0 sumZ 0.0 desc "")
    
    ;; Prepara as variáveis para medir a 'caixa' virtual em volta dos pontos
    (setq minX 1e99 maxX -1e99 minY 1e99 maxY -1e99)
    
    (setq i 0)
    (while (< i n)
      (setq ent (ssname ss i))
      (setq vla-ent (vlax-ename->vla-object ent))
      
      (setq pos (vlax-get vla-ent 'Location))
      (setq sumX (+ sumX (car pos)))
      (setq sumY (+ sumY (cadr pos)))
      (setq sumZ (+ sumZ (caddr pos)))
      
      ;; Converte a coordenada para o UCS para medir a forma no ângulo da tela
      (setq ptUCS (trans pos 0 1))
      (setq px (car ptUCS) py (cadr ptUCS))
      
      ;; Acha os limites máximos e mínimos (As "paredes" da forma)
      (if (< px minX) (setq minX px))
      (if (> px maxX) (setq maxX px))
      (if (< py minY) (setq minY py))
      (if (> py maxY) (setq maxY py))
      
      (if (= i 0)
        (progn
          (setq desc (vl-catch-all-apply 'vlax-get (list vla-ent 'RawDescription)))
          (if (or (vl-catch-all-error-p desc) (= desc nil) (= desc ""))
            (setq desc "Sem_Desc")
            (setq desc (vl-princ-to-string desc))
          )
        )
      )
      (setq i (1+ i))
    )
    
    (setq ptCentroWCS (list (/ sumX n) (/ sumY n) (/ sumZ n)))
    (setq ptCentroUCS (trans ptCentroWCS 0 1))
    
    ;; ================================================================
    ;; LÓGICA DE AUTO-ESCALA DO TEXTO
    ;; ================================================================
    (setq boxW (- maxX minX)) ; Largura total da forma
    (setq boxH (- maxY minY)) ; Altura total da forma
    (setq len (strlen desc))  ; Quantidade de letras no texto
    (if (= len 0) (setq len 1))
    
    ;; Calcula a altura máxima que o texto pode ter para não vazar a largura ou a altura (usando 80% do espaço para dar respiro)
    (setq maxH_W (/ (* boxW 0.8) (* len 0.75))) 
    (setq maxH_H (* boxH 0.8))
    
    ;; Escolhe a menor altura possível para garantir que caiba em todos os sentidos
    (setq idealHeight (min maxH_W maxH_H))
    
    ;; Trava de segurança: Se os pontos estiverem grudados ou for uma linha reta, usa o tamanho padrão
    (if (<= idealHeight 0.01) (setq idealHeight (getvar "TEXTSIZE")))
    
    (setvar "CMDECHO" 0)
    
    ;; Insere o Texto forçando a ALTURA (_H) matemática que acabamos de calcular
    (command "._MTEXT" "_non" ptCentroUCS "_H" idealHeight "_J" "_MC" "_non" ptCentroUCS desc "")
    
    (setvar "CMDECHO" 1)
    (princ (strcat "\nRótulo '" desc "' encaixado nos limites! Selecione a próxima forma..."))
  )
  
  (princ "\nComando finalizado.")
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
(defun c:point2mld ( / opt ss i ent vla-ent pos val strText pt1_ucs pt2_ucs east north rawLat rawLon lat lon format-dms )
  ;; Carrega as funções do Visual LISP
  (vl-load-com)
  
  ;; O padrão voltou a ser COTA. E as opções estão todas juntas.
  (initget "Cota Descricao UTM LatGraus LatDec")
  (setq opt (getkword "\nO que deseja exibir? [Cota / Descricao / UTM / LatGraus / LatDec] <Cota>: "))
  (if (not opt) (setq opt "Cota"))

  ;; Função formatação exata do Civil 3D (W048... S018...)
  (defun format-dms ( val axis / dir d m s d_str m_str s_str )
    (if (= axis "LAT")
      (if (< val 0.0) (setq dir "S") (setq dir "N"))
      (if (< val 0.0) (setq dir "W") (setq dir "E"))
    )
    (setq val (abs val))
    (setq d (fix val))
    (setq m (fix (* (- val d) 60.0)))
    (setq s (* (- (* (- val d) 60.0) m) 60.0))

    (setq d_str (itoa d))
    (if (< d 100)
      (if (< d 10) (setq d_str (strcat "00" d_str)) (setq d_str (strcat "0" d_str)))
    )
    (if (< m 10) (setq m_str (strcat "0" (itoa m))) (setq m_str (itoa m)))
    (if (< s 10) (setq s_str (strcat "0" (rtos s 2 2))) (setq s_str (rtos s 2 2)))
    
    (setq s_str (vl-string-translate "." "," s_str))
    (strcat dir d_str "%%d " m_str "' " s_str "\"")
  )

  (prompt (strcat "\nModo >> " opt " << ativado. Selecione os COGO Points: "))
  (setq ss (ssget '((0 . "AECC_COGO_POINT"))))
  
  (if ss
    (progn
      (setq i 0)
      (setvar "CMDECHO" 0)
      
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq vla-ent (vlax-ename->vla-object ent))
        (setq pos (vlax-get vla-ent 'Location))
        
        (cond
          ;; 1. COTA (PADRÃO)
          ((= opt "Cota")
            (setq val (vlax-get vla-ent 'Elevation))
            (setq strText (vl-string-translate "." "," (rtos val 2 3)))
          )
          
          ;; 2. DESCRIÇÃO
          ((= opt "Descricao")
            (setq strText (vl-catch-all-apply 'vlax-get (list vla-ent 'RawDescription)))
            (if (or (vl-catch-all-error-p strText) (= strText nil) (= strText ""))
              (setq strText "Sem_Desc")
              (setq strText (vl-princ-to-string strText))
            )
          )
          
          ;; 3. UTM
          ((= opt "UTM")
            (setq east (vl-catch-all-apply 'vlax-get (list vla-ent 'Easting)))
            (setq north (vl-catch-all-apply 'vlax-get (list vla-ent 'Northing)))
            (if (or (vl-catch-all-error-p east) (vl-catch-all-error-p north))
              (setq strText "Erro_UTM")
              (setq strText (strcat "E: " (vl-string-translate "." "," (rtos east 2 3)) "\\PN: " (vl-string-translate "." "," (rtos north 2 3))))
            )
          )
          
          ;; 4. LATITUDE E LONGITUDE (O SEGREDO DA CONVERSÃO DE RADIANOS)
          ((or (= opt "LatGraus") (= opt "LatDec"))
            ;; Pega o metadado puro do COGO Point (que vem em radianos)
            (setq rawLat (vl-catch-all-apply 'vlax-get (list vla-ent 'Latitude)))
            (setq rawLon (vl-catch-all-apply 'vlax-get (list vla-ent 'Longitude)))
            
            (if (or (vl-catch-all-error-p rawLat) (vl-catch-all-error-p rawLon))
              (setq strText "Erro_Georef")
              (progn
                ;; CONVERTE RADIANOS PARA GRAUS para o Civil 3D parar de te sacanear
                (setq lat (* rawLat (/ 180.0 pi)))
                (setq lon (* rawLon (/ 180.0 pi)))
                
                (if (= opt "LatGraus")
                  (setq strText (strcat "Lat: " (format-dms lat "LAT") "\\PLon: " (format-dms lon "LON")))
                  (setq strText (strcat "Lat: " (vl-string-translate "." "," (rtos lat 2 6)) "\\PLon: " (vl-string-translate "." "," (rtos lon 2 6))))
                )
              )
            )
          )
        )
        
        (setq pt1_ucs (trans pos 0 1))
        (setq pt2_ucs (list (+ (car pt1_ucs) 5.0) (+ (cadr pt1_ucs) 5.0) 0.0))
        
        (command "._MLEADER" "_non" pt1_ucs "_non" pt2_ucs strText)
        
        (setq i (1+ i))
      )
      
      (setvar "CMDECHO" 1)
      (princ (strcat "\nSucesso! Foram criadas " (itoa i) " MLDs no modo " opt "!"))
    )
    (princ "\nNenhum COGO Point selecionado.")
  )
  (princ)
)
      ;;feito por gabriela braga oliveira @redmargoth
require "google_drive"

# Creates a session. This will prompt the credential via command line for the
# first time and save it to config.json file for later usages.
# See this document to learn how to create config.json:
# https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md
session = GoogleDrive::Session.from_config("config.json")

ws = session.spreadsheet_by_key('1q2ZdYCwVr50Nue8s0oq0kAMsx8AZfSATgDkgRs5V11M')
class Tabela 
    include Enumerable
    @@brojac = 0
    attr_accessor :sheets, :tabela, :kolone, :indeks, :prvired, :prvakolona, :brredova, :brkolona, :worksheet
    def initialize(worksheet)
      @worksheet = worksheet.worksheets[@@brojac]
      @@brojac +=1
      @tabela = []
      @kolone = []
      @prazni_redovi = [] 
      @indeks = {}
      @prvired = nil
      @prvakolona = nil
      @brredova 
      @brkolona 
    end

    def each
      if block_given?
        @tabela.each do |red|
          red.each do |kol|
              yield kol
          end
        end
      end
    end
    
    def pravljenjeTabele
      (1...@worksheet.num_rows).each do |red_indeks|
        break unless @prvired.nil? && @prvakolona.nil?
        (1...@worksheet.num_cols).each do |kolona_indeks|
          celija = @worksheet[red_indeks,kolona_indeks]
          if celija != '' && @prvired.nil? && @prvakolona.nil?
            @prvired = red_indeks 
            @prvakolona = kolona_indeks 
          end
        end
      end
      @brredova = @worksheet.num_rows - @prvired + 1
      @brkolona = @worksheet.num_cols - @prvakolona + 1
    end

    def heder
      (@prvakolona..@worksheet.num_cols).each do |kol|
        @kolone.append(@worksheet[@prvired, kol])
      end
    end

    def popuniTabelu
      (@prvired+1..@brredova+@prvired-1).each do |red| 
        niz = []
        (@prvakolona..@brkolona+@prvakolona).each do |kolona|
          celija = @worksheet[red, kolona]
          if celija != ''
            niz.append(celija)
          end
          if celija == '' || celija == 'subtotal' || celija == 'total'
            if celija == ''
              @prazni_redovi.append(red)
            end
            break
          end
        end
        @tabela.append(niz)
      end
    end

    def row(broj)
      @tabela[broj-1]
    end

    def [](vrednost)
      niz = []
      @tabela.each do |red|
        (0..red.size-1).each do |kol|
          if @kolone[kol] == vrednost
            niz.append(red[kol])
          end
        end
      end
      return niz
    end

    def[]=(kljuc, indeks, vrednost)
      puts indeks
      puts vrednost
      if @kolone.include?(kljuc) 
        kolona = @kolone.index(kljuc) 
        @tabela[indeks][kolona] = vrednost
      elsif indeks.is_a?(Integer) && indeks >= 0 && indeks < @tabela.length 
        @tabela[indeks] = vrednost
      end
     
    end
    
    def method_missing(symbol, *args)
      # mozemo da se oslonimo na gornju metodu [] i da je pozovemo nad self sa symbol kao argumentom
    end

    def +(tabela2)
      if(iste(tabela2))
        #@ws.add_worksheet("nn")
        t = []
        (0..@brredova+tabela2.brredova).each do |i|
            if @tabela.size > i
              t.append(@tabela[i])
            end
            if tabela2.tabela.size > i 
              t.append(tabela2.tabela[i])
            end
        end
        return t
      end
    end
  
    def -(tabela2)
      if(iste(tabela2))
        t = []
        n = []
        @tabela.each do |red|
          if tabela2.tabela.any? { |red2| red2 == red }
            (0..@brkolona-1).each do |kol|
              n[kol] = ''
            end
            t.append(n)
          else 
            t.append(red)
          end
        end
        return t
      end
    end
  
    def iste(drugaTabela)
      if drugaTabela.instance_of?(Tabela) && @kolone == drugaTabela.kolone
        return true
      end
      return false
    end


end

t = Tabela.new(ws)

t.pravljenjeTabele
t.heder
t.popuniTabelu
#puts t.tabela
# t.each do |celija|
#   puts celija
# end
#puts t.row(1)[1]
# p t["PrvaKolona"]
# t["PrvaKolona"][2]=1
t2 = Tabela.new(ws)
t2.pravljenjeTabele
t2.heder
t2.popuniTabelu
p t+t2
p t-t2
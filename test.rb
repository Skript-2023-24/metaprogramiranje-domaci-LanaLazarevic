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
    attr_accessor :sheets, :tabela, :kolone, :indeks, :prvired, :prvakolona, :brredova, :brkolona, :worksheet

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

    def imeKolone(ime)
      if(!!(ime=~ /\s/))
        reci = ime.split(' ') 
        reci.each do |rec| 
          rec.downcase!  
        end
        konacnoime = reci.join('')
        return konacnoime
      end
      return ime
    end

    def uzmiIndekse
      (0..@brkolona-1).each do |kol|
          ime = imeKolone(@kolone[kol])
          @indeks[ime] = Kolona.new(self, kolonaSadrzaj(kol))
      end
    end

    def popuniTabelu
      (@prvired+1..@brredova+@prvired-1).each do |red| 
        niz = []
        b = true
        (@prvakolona..@brkolona+@prvakolona-1).each do |kolona|
          celija = @worksheet[red, kolona]
          if celija == 'subtotal' || celija == 'total'
            break
            b=false
          end
          niz.append(celija)
          # if celija == '' || celija == 'subtotal' || celija == 'total'
          #   if celija == ''
          #     @prazni_redovi.append(red)
          #   end
          #   break
          # end
        end
        if(b==true)
          @tabela.append(niz)
        end
      end
    end

    def row(broj)
      @tabela[broj-1]
    end

    def kolonaSadrzaj(broj)
      @tabela.transpose[broj]
    end

    def [](vrednost)
      #indeks[imeKolone(vrednost)].kolona
      indeks[imeKolone(vrednost)]
    end
    
    def method_missing(symbol, *args)
      p symbol
      self[symbol]
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

class Kolona

  def initialize(tabela,kolona) 
    @mojaTabela = tabela
    @kolona = kolona
  end

  attr_accessor :mojaTabela, :kolona

  def nizBrojeva(kolona)
    niz = []
    (0..kolona.size-1).each do |i|
      niz.append(kolona[i].to_i)
    end
    return niz
  end

  def sum(init = nil)
    return nizBrojeva(@kolona).sum
  end

  def method_missing(symbol, *args, &block)
    p "uslo"
    case symbol.to_s.downcase
    when 'reduce'
      brojevi = nizBrojeva(@kolona)
      brojevi.reduce(args[1].to_sym)
    when 'select'
      brojevi = nizBrojeva(@kolona)
      brojevi.select(&block)
    when 'map'
      brojevi = nizBrojeva(@kolona)
      brojevi.map(&block)
    when 'avg'
      brojevi = nizBrojeva(@kolona)
      1.0 * brojevi.sum / brojevi.size
    else
      vrednost = symbol
      indeks = promeniKolonuUTabeli(vrednost) 
      @mojaTabela.tabela[indeks] if indeks
    end
  end
  
  def pronadjiIneksReda(vrednost)
    (0..@kolona.size-1).each do |i|
      return i if @kolona[i] == vrednost
    end
  end

  def indeks
    @mojaTabela.indeks.each_with_index do |(key, value), index|
      return index if value == self
    end
  end

  def [](vrednost)
    @mojaTabela.tabela[vrednost][self.indeks]
  end

  def[]=(indeks,vrednost)
    @mojaTabela.tabela[indeks][self.indeks] = vrednost
    @mojaTabela.worksheet.save
    @mojaTabela.worksheet.reload
  end


end


t = Tabela.new(ws)

t.pravljenjeTabele
t.heder
t.popuniTabelu
t.uzmiIndekse
# t.each do |celija|
#   puts celija
# end
# puts t.row(1)[1]
p t["PrvaKolona"]
p t["PrvaKolona"][2]
p t["PrvaKolona"][2] = "1"
p t.tabela

# t2 = Tabela.new(ws)
# t2.pravljenjeTabele
# t2.heder
# t2.popuniTabelu
# p t+t2
# p t-t2


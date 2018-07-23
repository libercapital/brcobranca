# -*- encoding: utf-8 -*-
#
require 'unidecoder'

module Brcobranca
  module Brpagamento
    module Remessa
      class Base
        # Validações do Rails 3
        include ActiveModel::Validations

        attr_accessor :pagamentos

        validates_presence_of :pagamentos, message: 'não pode estar em branco.'

        validates_each :pagamentos do |record, attr, value|
          if value.is_a? Array
            record.errors.add(attr, 'não pode estar vazio.') if value.empty?
            value.each do |pagamento|
              if pagamento.is_a? Brcobranca::Brpagamento::Remessa::Pagamento
                if pagamento.invalid?
                  pagamento.errors.full_messages.each { |msg| record.errors.add(attr, msg) }
                end
              else
                record.errors.add(attr, 'cada item deve ser um objeto Pagamento.')
              end
            end
          else
            record.errors.add(attr, 'deve ser uma coleção (Array).')
          end
        end

        # Nova instancia da classe
        #
        # @param campos [Hash]
        #
        def initialize(campos = {})
          campos = { }.merge!(campos)
          campos.each do |campo, valor|
            send "#{campo}=", valor
          end

          yield self if block_given?
        end

        # Soma de todos os boletos
        #
        # @return [String]
        def valor_total_titulos(tamanho = 13)
          value = pagamentos.inject(0.0) { |sum, pagamento| sum += pagamento.valor }
          sprintf('%.2f', value).delete('.').rjust(tamanho, '0')
        end

        def lista_ISPB(banco)
          #Cod banco Cod ISPB Banco
          lista = {
            '001': '00000000',   # BCO DO BRASIL S.A.
            '070': '00000208',   # BRB - BCO DE BRASILIA S.A.
            '136': '00315557',   # CONF NAC COOP CENTRAIS UNICRED
            '104': '00360305',   # CAIXA ECONOMICA FEDERAL
            '077': '00416968',   # BANCO INTER
            '741': '00517645',   # BCO RIBEIRAO PRETO S.A.
            '739': '00558456',   # BCO CETELEM S.A.
            '743': '00795423',   # BANCO SEMEAR
            '100': '00806535',   # PLANNER CV S.A.
            '096': '00997185',   # BCO B3 S.A.
            '747': '01023570',   # BCO RABOBANK INTL BRASIL S.A.
            '748': '01181521',   # BCO COOPERATIVO SICREDI S.A.
            '752': '01522368',   # BCO BNP PARIBAS BRASIL S A
            '091': '01634601',   # CCCM UNICRED CENTRAL RS
            '399': '01701201',   # KIRTON BANK
            '108': '01800019',   # PORTOCRED S.A. - CFI
            '756': '02038232',   # BANCOOB
            '757': '02318507',   # BCO KEB HANA DO BRASIL S.A.
            '102': '02332886',   # XP INVESTIMENTOS CCTVM S/A
            '084': '02398976',   # UNIPRIME NORTE DO PARANÁ - CC
            '180': '02685483',   # CM CAPITAL MARKETS CCTVM LTDA
            '066': '02801938',   # BCO MORGAN STANLEY S.A.
            '015': '02819125',   # UBS BRASIL CCTVM S.A.
            '143': '02992317',   # TREVISO CC S.A.
            '062': '03012230',   # HIPERCARD BM S.A.
            '074': '03017677',   # BCO. J.SAFRA S.A.
            '099': '03046391',   # UNIPRIME CENTRAL CCC LTDA.
            '025': '03323840',   # BCO ALFA S.A.
            '075': '03532415',   # BCO ABN AMRO S.A.
            '040': '03609817',   # BCO CARGILL S.A.
            '190': '03973814',   # SERVICOOP
            '063': '04184779',   # BANCO BRADESCARD
            '191': '04257795',   # NOVA FUTURA CTVM LTDA.
            '064': '04332281',   # GOLDMAN SACHS DO BRASIL BM S.A
            '097': '04632856',   # CCC NOROESTE BRASILEIRO LTDA.
            '016': '04715685',   # CCM DESP TRÂNS SC E RS
            '012': '04866275',   # BANCO INBURSA
            '003': '04902979',   # BCO DA AMAZONIA S.A.
            '060': '04913129',   # CONFIDENCE CC S.A.
            '037': '04913711',   # BCO DO EST. DO PA S.A.
            '159': '05442029',   # CASA CREDITO S.A. SCM
            '172': '05452073',   # ALBATROSS CCV S.A
            '085': '05463212',   # COOP CENTRAL AILOS
            '114': '05790149',   # CENTRAL COOPERATIVA DE CRÉDITO NO ESTADO DO ESPÍRITO SANTO
            '036': '06271464',   # BCO BBI S.A.
            '394': '07207996',   # BCO BRADESCO FINANC. S.A.
            '004': '07237373',   # BCO DO NORDESTE DO BRASIL S.A.
            '320': '07450604',   # BCO CCB BRASIL S.A.
            '189': '07512441',   # HS FINANCEIRA
            '105': '07652226',   # LECCA CFI S.A.
            '076': '07656500',   # BCO KDB BRASIL S.A.
            '082': '07679404',   # BANCO TOPÁZIO S.A.
            '093': '07945233',   # PÓLOCRED SCMEPP LTDA.
            '273': '08253539',   # CCR DE SÃO MIGUEL DO OESTE
            '157': '09105360',   # ICAP DO BRASIL CTVM LTDA.
            '183': '09210106',   # SOCRED S.A. SCM
            '014': '09274232',   # NATIXIS BRASIL S.A. BM
            '130': '09313766',   # CARUANA SCFI
            '127': '09512542',   # CODEPE CVC S.A.
            '079': '09516419',   # BCO ORIGINAL DO AGRO S/A
            '081': '10264663',   # BBN BCO BRASILEIRO DE NEGOCIOS S.A.
            '133': '10398952',   # CRESOL CONFEDERAÇÃO
            '121': '10664513',   # BCO AGIBANK S.A.
            '083': '10690848',   # BCO DA CHINA BRASIL S.A.
            '138': '10853017',   # GET MONEY CC LTDA
            '024': '10866788',   # BCO BANDEPE S.A.
            '095': '11703662',   # BCO CONFIDENCE DE CÂMBIO S.A.
            '094': '11758741',   # BANCO FINAXIS
            '118': '11932017',   # STANDARD CHARTERED BI S.A.
            '276': '11970623',   # SENFF S.A. - CFI
            '137': '12586596',   # MULTIMONEY CC LTDA.
            '092': '12865507',   # BRK S.A. CFI
            '047': '13009717',   # BCO DO EST. DE SE S.A.
            '144': '13059145',   # BEXS BCO DE CAMBIO S.A.
            '126': '13220493',   # BR PARTNERS BI
            '173': '13486793',   # BRL TRUST DTVM SA
            '119': '13720915',   # BCO WESTERN UNION
            '254': '14388334',   # PARANA BCO S.A.
            '268': '14511781',   # BARIGUI CH
            '107': '15114366',   # BCO BOCOM BBM S.A.
            '412': '15173776',   # BCO CAPITAL S.A.
            '124': '15357060',   # BCO WOORI BANK DO BRASIL S.A.
            '149': '15581638',   # FACTA S.A. CFI
            '197': '16501555',   # STONE PAGAMENTOS S.A.
            '142': '16944141',   # BROKER BRASIL CC LTDA.
            '389': '17184037',   # BCO MERCANTIL DO BRASIL S.A.
            '184': '17298092',   # BCO ITAÚ BBA S.A.
            '634': '17351180',   # BCO TRIANGULO S.A.
            '545': '17352220',   # SENSO CCVM S.A.
            '132': '17453575',   # ICBC DO BRASIL BM S.A.
            '260': '18236120',   # NU PAGAMENTOS S.A.
            '129': '18520834',   # UBS BRASIL BI S.A.
            '128': '19307785',   # MS BANK S.A. BCO DE CÂMBIO
            '194': '20155248',   # PARMETAL DTVM LTDA
            '163': '23522214',   # COMMERZBANK BRASIL S.A. - BCO MÚLTIPLO
            '280': '23862762',   # AVISTA S.A. CFI
            '146': '24074692',   # GUITTA CC LTDA
            '279': '26563270',   # CCR DE PRIMAVERA DO LESTE
            '182': '27406222',   # DACASA FINANCEIRA S/A - SCFI
            '278': '27652684',   # GENIAL INVESTIMENTOS CVM S.A.
            '271': '27842177',   # IB CCTVM LTDA
            '021': '28127603',   # BCO BANESTES S.A.
            '246': '28195667',   # BCO ABC BRASIL S.A.
            '751': '29030467',   # SCOTIABANK BRASIL
            '208': '30306294',   # BANCO BTG PACTUAL S.A.
            '746': '30723886',   # BCO MODAL S.A.
            '241': '31597552',   # BCO CLASSICO S.A.
            '612': '31880826',   # BCO GUANABARA S.A.
            '604': '31895683',   # BCO INDUSTRIAL DO BRASIL S.A.
            '505': '32062580',   # BCO CREDIT SUISSE (BRL) S.A.
            '196': '32648370',   # FAIR CC S.A.
            '300': '33042151',   # BCO LA NACION ARGENTINA
            '477': '33042953',   # CITIBANK N.A.
            '266': '33132044',   # BCO CEDULA S.A.
            '122': '33147315',   # BCO BRADESCO BERJ S.A.
            '376': '33172537',   # BCO J.P. MORGAN S.A.
            '473': '33466988',   # BCO CAIXA GERAL BRASIL S.A.
            '745': '33479023',   # BCO CITIBANK S.A.
            '120': '33603457',   # BCO RODOBENS S.A.
            '265': '33644196',   # BCO FATOR S.A.
            '007': '33657248',   # BNDES
            '188': '33775974',   # ATIVA S.A. INVESTIMENTOS CCTVM
            '134': '33862244',   # BGC LIQUIDEZ DTVM LTDA
            '641': '33870163',   # BCO ALVORADA S.A.
            '029': '33885724',   # BANCO ITAÚ CONSIGNADO S.A.
            '243': '33923798',   # BCO MÁXIMA S.A.
            '078': '34111187',   # HAITONG BI DO BRASIL S.A.
            '111': '36113876',   # OLIVEIRA TRUST DTVM S.A.
            '017': '42272526',   # BNY MELLON BCO S.A.
            '174': '43180355',   # PERNAMBUCANAS FINANC S.A. CFI
            '495': '44189447',   # BCO LA PROVINCIA B AIRES BCE
            '125': '45246410',   # BRASIL PLURAL S.A. BCO.
            '488': '46518205',   # JPMORGAN CHASE BANK
            '065': '48795256',   # BCO ANDBANK S.A.
            '492': '49336860',   # ING BANK N.V.
            '145': '50579044',   # LEVYCAM CCV LTDA
            '250': '50585090',   # BCV
            '494': '51938876',   # BCO REP ORIENTAL URUGUAY BCE
            '253': '52937216',   # BEXS CC S.A.
            '269': '53518684',   # HSBC BANCO DE INVESTIMENTO
            '213': '54403563',   # BCO ARBI S.A.
            '139': '55230916',   # INTESA SANPAOLO BRASIL S.A. BM
            '018': '57839805',   # BCO TRICURY S.A.
            '422': '58160789',   # BCO SAFRA S.A.
            '630': '58497702',   # BCO INTERCAP S.A.
            '224': '58616418',   # BCO FIBRA S.A.
            '600': '59118133',   # BCO LUSO BRASILEIRO S.A.
            '623': '59285411',   # BANCO PAN
            '204': '59438325',   # BCO BRADESCO CARTOES S.A.
            '655': '59588111',   # BCO VOTORANTIM S.A.
            '479': '60394079',   # BCO ITAUBANK S.A.
            '456': '60498557',   # BCO MUFG BRASIL S.A.
            '464': '60518222',   # BCO SUMITOMO MITSUI BRASIL S.A.
            '341': '60701190',   # ITAÚ UNIBANCO BM S.A.
            '237': '60746948',   # BCO BRADESCO S.A.
            '613': '60850229',   # OMNI BANCO S.A.
            '652': '60872504',   # ITAÚ UNIBANCO HOLDING BM S.A.
            '637': '60889128',   # BCO SOFISA S.A.
            '653': '61024352',   # BCO INDUSVAL S.A.
            '069': '61033106',   # BCO CREFISA S.A.
            '370': '61088183',   # BCO MIZUHO S.A.
            '249': '61182408',   # BANCO INVESTCRED UNIBANCO S.A.
            '318': '61186680',   # BCO BMG S.A.
            '626': '61348538',   # BCO FICSA S.A.
            '366': '61533584',   # BCO SOCIETE GENERALE BRASIL
            '113': '61723847',   # MAGLIANO S.A. CCVM
            '131': '61747085',   # TULLETT PREBON BRASIL CVC LTDA
            '011': '61809182',   # C.SUISSE HEDGING-GRIFFO CV S/A
            '611': '61820817',   # BCO PAULISTA S.A.
            '755': '62073200',   # BOFA MERRILL LYNCH BM S.A.
            '089': '62109566',   # CCR REG MOGIANA
            '643': '62144175',   # BCO PINE S.A.
            '140': '62169875',   # EASYNVEST - TÍTULO CV SA
            '707': '62232889',   # BCO DAYCOVAL S.A
            '288': '62237649',   # CAROL DTVM LTDA.
            '101': '62287735',   # RENASCENCA DTVM LTDA
            '487': '62331228',   # DEUTSCHE BANK S.A.BCO ALEMAO
            '233': '62421979',   # BANCO CIFRA
            '177': '65913436',   # GUIDE
            '633': '68900810',   # BCO RENDIMENTO S.A.
            '218': '71027866',   # BCO BS2 S.A.
            '169': '71371686',   # BCO OLÉ BONSUCESSO CONSIGNADO S.A.
            '080': '73622748',   # B&T CC LTDA.
            '753': '74828799',   # NOVO BCO CONTINENTAL S.A. - BM
            '222': '75647891',   # BCO CRÉDIT AGRICOLE BR S.A.
            '754': '76543115',   # BANCO SISTEMA
            '098': '78157146',   # CREDIALIANÇA CCR
            '610': '78626983',   # BCO VR S.A.
            '712': '78632767',   # BCO OURINVEST S.A.
            '010': '81723108',   # CREDICOAMO
            '283': '89960090',   # RB CAPITAL INVESTIMENTOS DTVM LTDA.
            '033': '90400888',   # BCO SANTANDER (BRASIL) S.A.
            '217': '91884981',   # BANCO JOHN DEERE S.A.
            '041': '92702067',   # BCO DO ESTADO DO RS S.A.
            '117': '92856905',   # ADVANCED CC LTDA
            '654': '92874270',   # BCO A.J. RENNER S.A.
            '212': '92894922'    # BANCO ORIGINAL
          }

          lista[banco.to_sym]
        end
      end
    end
  end
end
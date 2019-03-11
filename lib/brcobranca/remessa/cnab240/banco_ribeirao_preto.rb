# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Remessa
    module Cnab240
      class BancoRibeiraoPreto < Brcobranca::Remessa::Cnab240::Base
        # Conf BRP to BRP        attr_accessor :count_lotes
        attr_accessor :remessa_interna # remessa gerada para o proprio BRP
        attr_accessor :direcionamento_cobranca
        attr_accessor :modalidade_cobranca
        attr_accessor :modalidade_cobranca_nossa_carteira

        validates_presence_of :convenio, message: 'não pode estar em branco.'
        validates_length_of :conta_corrente, maximum: 12, message: 'deve ter 12 dígitos.'
        validates_length_of :agencia, maximum: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :convenio, in: 4..20, message: 'deve ter de 4 a 7 dígitos.'

        def initialize(campos = {})
          campos = { remessa_interna: false,
                     direcionamento_cobranca: '3',
                     modalidade_cobranca: '110',
                     modalidade_cobranca_nossa_carteira: '112',
                     especie_titulo: '02',
                     emissao_boleto: '1',
                     distribuicao_boleto: '1',
                     aceite: 'A'
                    }.merge!(campos)
          super(campos)
        end

        def cod_banco
          '741'
        end

        def nome_banco
          'BANCO RIBEIRAO PRETO S/A'.ljust(30, ' ')
        end

        def versao_layout_arquivo
          '040'
        end

        def versao_layout_lote
          '030'
        end

        def densidade_gravacao
          '01600'
        end

        def codigo_convenio
          convenio.to_s.ljust(20, ' ')
        end

        def digito_agencia
          # utilizando a agencia com 4 digitos
          # para calcular o digito
          return '0' if remessa_interna
          agencia.modulo11(mapeamento: { 10 => 'X' }).to_s
        end

        def digito_conta
          # utilizando a conta corrente com 5 digitos
          # para calcular o digito
          return ' ' if remessa_interna
          conta_corrente.modulo11(mapeamento: { 10 => 'X' }).to_s
        end

        # Data de geracao do arquivo
        #
        # @return [String]
        #
        def data_geracao
          Date.current.strftime('%d%m%Y')
        end

        # Hora de geracao do arquivo
        #
        # @return [String]
        #
        def hora_geracao
          Time.current.strftime('%H%M%S')
        end

        def counter_lotes(count, just = 4)
          remessa_interna ? count.to_s.rjust(just, '0') : '1'.ljust(just, ' ')
        end

        def formata_nosso_numero(numero)
          return ''.rjust(20, ' ') if remessa_interna
          return '' if numero.nil? || numero.blank?

          nosso_numero = numero.to_s.rjust(10, '0')
          dv = "#{modalidade_cobranca_nossa_carteira}#{nosso_numero.rjust(10, '0')}".modulo11(
            multiplicador: [2, 1],
            mapeamento: { 10 => 'P', 11 => 0 }
          ) { |total| 11 - (total % 11) }

          "#{nosso_numero}#{dv}"
        end

        # Monta o registro header do arquivo
        #
        # @return [String]
        #
        def monta_header_arquivo
          header_arquivo = ''                                                              # Descrição                           Posição    Tamanho
          header_arquivo << cod_banco                                                      # Código do Banco na Compensação      [1.. ...3] 03
          header_arquivo << '0000'                                                         # Lote de Serviço                     [4.. ...7] 04
          header_arquivo << '0'                                                            # Tipo de Registro                    [8.. ...8] 01
          header_arquivo << ''.rjust(9, ' ')                                               # Uso Exclusivo FEBRABAN / CNAB       [9.....17] 09
          header_arquivo << Brcobranca::Util::Empresa.new(documento_cedente, false).tipo   # Tipo de Inscrição da Empresa        [18....18] 01
          header_arquivo << documento_cedente.to_s.rjust(14, '0')                          # Número de Inscrição da Empresa      [19....32] 14
          header_arquivo << codigo_convenio                                                # Código do Convênio no Banco         [33....52] 20
          header_arquivo << agencia.rjust(5, '0')                                          # Agência Mantenedora da Conta        [53....57] 05
          header_arquivo << digito_agencia                                                 # Dígito Verificador da Agência       [58....58] 01
          header_arquivo << conta_corrente.ljust(12, ' ')                                  # Número da Conta Corrente            [59....70] 12
          header_arquivo << digito_conta                                                   # Dígito Verificador da Conta         [71....71] 01
          header_arquivo << ' '                                                            # Dígito Verificador da AG/Conta      [72....72] 01
          header_arquivo << empresa_mae.format_size(30)                                    # Nome da Empresa                     [73...102] 30
          header_arquivo << nome_banco.format_size(30)                                     # Nome do Banco                       [103..132] 30
          header_arquivo << ''.rjust(10, ' ')                                              # Uso Exclusivo FEBRABAN / CNAB       [133..142] 10
          header_arquivo << '1'                                                            # Código Remessa / Retorno            [143..143] 01
          header_arquivo << data_geracao                                                   # Data de Geração do Arquivo          [144..151] 08
          header_arquivo << hora_geracao                                                   # Hora de Geração do Arquivo          [152..157] 06
          header_arquivo << sequencial_remessa.to_s.rjust(6, '0')                          # Número Seqüencial do Arquivo        [158..163] 06
          header_arquivo << versao_layout_arquivo                                          # No da Versão do Layout do Arquivo   [164..166] 03
          header_arquivo << densidade_gravacao                                             # Densidade de Gravação do Arquivo    [167..171] 05
          header_arquivo << ''.rjust(20, ' ')                                              # Para Uso Reservado do Banco         [172..191] 20
          header_arquivo << ''.rjust(20, ' ')                                              # Para Uso Reservado da Empresa       [192..211] 20
          header_arquivo << ''.rjust(11, ' ')                                              # Uso Exclusivo FEBRABAN / CNAB       [212..222] 11
          header_arquivo << 'CSP'                                                          # Identificação da Cobrança sem Papel [223..225] 03
          header_arquivo << '000'                                                          # Uso Exclusivo da VANs               [226..228] 03
          header_arquivo << ''.rjust(2, ' ')                                               # Tipo de Serviço Cobrança sem Papel  [229..230] 02
          header_arquivo << ''.rjust(10, ' ')                                              # Cód. Ocor. Cobrança sem Papel       [231..240] 10
          header_arquivo
        end

        # Monta o registro header do lote
        #
        # @param nro_lote [Integer]
        #   numero do lote no arquivo (iterar a cada novo lote)
        #
        # @return [String]
        #
        def monta_header_lote(nro_lote)
          header_lote = ''                                                                 # Descrição                        Posição    Tamanho
          header_lote << cod_banco                                                         # Código do Banco na Compensação   [1......3] 03
          header_lote << counter_lotes(nro_lote)                                           # Lote de Serviço                  [4......7] 04
          header_lote << '1'                                                               # Tipo de Registro                 [8......8] 01
          header_lote << 'R'                                                               # Tipo de Operação                 [9......9] 01
          header_lote << '01'                                                              # Tipo de Serviço                  [10....11] 02
          header_lote << ''.rjust(2, ' ')                                                  # Uso Exclusivo FEBRABAN/CNAB      [12....13] 02
          header_lote << versao_layout_lote                                                # Nº da Versão do Layout do Lote   [14....16] 03
          header_lote << ''.rjust(1, ' ')                                                  # Uso Exclusivo FEBRABAN/CNAB      [17....17] 01
          header_lote << Brcobranca::Util::Empresa.new(documento_cedente, false).tipo      # Tipo de Inscrição da Empresa     [18....18] 01
          header_lote << documento_cedente.to_s.rjust(15, '0')                             # Nº de Inscrição da Empresa       [19....33] 15
          header_lote << codigo_convenio                                                   # Código do Convênio no Banco      [34....53] 20
          header_lote << agencia.rjust(5, '0')                                             # Agência Mantenedora da Conta     [54....58] 05
          header_lote << digito_agencia                                                    # Dígito Verificador da Conta      [59....59] 01
          header_lote << conta_corrente.ljust(12, ' ')                                     # Número da Conta Corrente         [60....71] 12
          header_lote << digito_conta                                                      # Dígito Verificador da Conta      [72....72] 01
          header_lote << ' '                                                               # Dígito Verificador da Ag/Conta   [73....73] 01
          header_lote << empresa_mae.format_size(30)                                       # Nome da Empresa                  [74...103] 30
          header_lote << ''.ljust(40, ' ')                                                 # Mensagem 1                       [104..143] 40
          header_lote << ''.ljust(40, ' ')                                                 # Mensagem 2                       [144..183] 40
          header_lote << sequencial_remessa.to_s.rjust(8, '0')                             # Número Remessa/Retorno           [184..191] 08
          header_lote << data_geracao                                                      # Data de Gravação Remessa/Retorno [192..199] 08
          header_lote << data_geracao                                                      # Data do Crédito                  [200..207] 08
          header_lote << ''.ljust(33, ' ')                                                 # Uso Exclusivo FEBRABAN/CNAB      [208..240] 33
          header_lote
        end

        # Monta o registro segmento P do arquivo
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        #   objeto contendo os detalhes do boleto (valor, vencimento, sacado, etc)
        # @param nro_lote [Integer]
        #   numero do lote que o segmento esta inserido
        # @param sequencial [Integer]
        #   numero sequencial do registro no lote
        #
        # @return [String]
        #
        def monta_segmento_p(pagamento, nro_lote, sequencial)
          # campos com * na frente nao foram implementados
          segmento_p = ''                                                                  # Descrição                                  Posição    Tamanho
          segmento_p << cod_banco                                                          # Código do Banco na Compensação             [1......3] 03
          segmento_p << counter_lotes(nro_lote)                                            # Lote de Serviço                            [4......7] 04
          segmento_p << '3'                                                                # Tipo de Registro                           [8......8] 01
          segmento_p << sequencial.to_s.rjust(5, '0')                                      # Nº Sequencial do Registro no Lote          [9.....13] 05
          segmento_p << 'P'                                                                # Cód. Segmento do Registro Detalhe          [14....14] 01
          segmento_p << ' '                                                                # Uso Exclusivo FEBRABAN/CNAB                [15....15] 01
          segmento_p << '01'                                                               # Código de Movimento Remessa                [16....17] 02
          segmento_p << agencia.to_s.rjust(5, '0')                                         # Agência Mantenedora da Conta               [18....22] 05
          segmento_p << digito_agencia                                                     # Dígito Verificador da Agência              [23....23] 01
          segmento_p << conta_corrente.ljust(12, ' ')                                      # Número da Conta Corrente                   [24....35] 12
          segmento_p << digito_conta                                                       # Dígito Verificador da Conta                [36....36] 01
          segmento_p << ' '                                                                # Dígito Verificador da Ag/Conta             [37....37] 01
          segmento_p << direcionamento_cobranca                                            # Direcionamento da Cobrança                 [38....38] 01
          segmento_p << modalidade_cobranca                                                # Mod. de Cobrança em Bancos Correspondentes [39....41] 03
          segmento_p << ''.rjust(2, '0')                                                   # Uso exclusivo AUTBANK                      [42....43] 02
          segmento_p << modalidade_cobranca_nossa_carteira                                 # Mod. de Cobrança com o Banco Cedente       [44....46] 03
          segmento_p << ''.rjust(11, '0')                                                  # Identificação do Título no Banco           [47....57] 11
          segmento_p << codigo_carteira                                                    # Código da Carteira                         [58....58] 01
          segmento_p << '1'                                                                # Forma de Cadastr. do Título no Banco       [59....59] 01
          segmento_p << '2'                                                                # Tipo de Documento                          [60....60] 01
          segmento_p << emissao_boleto                                                     # Identificação da Emissão do Bloqueto       [61....61] 01
          segmento_p << distribuicao_boleto                                                # Identificação da Distribuição              [62....62] 01
          segmento_p << pagamento.uso_da_empresa.to_s.ljust(15, ' ')                       # Número do Documento de Cobrança            [63....77] 15
          segmento_p << pagamento.data_vencimento.strftime('%d%m%Y')                       # Data de Vencimento do Título               [78....85] 08
          segmento_p << pagamento.formata_valor(15)                                        # Valor Nominal do Título                    [86...100] 13 | 2
          segmento_p << ''.rjust(5, '0')                                                   # Agência Encarregada da Cobrança            [101..105] 05
          segmento_p << ''.rjust(1, '0')                                                   # Dígito Verificador da Agência              [106..106] 01
          segmento_p << especie_titulo                                                     # Espécie do Título                          [107..108] 02
          segmento_p << aceite                                                             # Identific. de Título Aceito/Não Aceito     [109..109] 01
          segmento_p << pagamento.data_emissao.strftime('%d%m%Y')                          # Data da Emissão do Título                  [110..117] 08
          segmento_p << pagamento.codigo_multa                                             # Código do Juros de Mora                    [118..118] 01
          segmento_p << pagamento.formata_data_multa('%d%m%Y')                             # Data do Juros de Mora                      [119..126] 08
          segmento_p << pagamento.formata_valor_mora(15)                                   # Juros de Mora por Dia/Taxa                 [127..141] 13 | 2
          segmento_p << ''.rjust(1, '0')                                                   # Código do Desconto 1                       [142..142] 01
          segmento_p << ''.rjust(8, '0')                                                   # Data do Desconto 1                         [143..150] 08
          segmento_p << ''.rjust(15, '0')                                                  # Valor/Percentual a ser Concedido           [151..165] 13
          segmento_p << ''.rjust(15, '0')                                                  # Valor do IOF a ser Recolhido               [166..180] 13
          segmento_p << pagamento.formata_valor_abatimento(15)                             # Valor do Abatimento                        [181..195] 13 | 2
          segmento_p << pagamento.numero_documento.to_s.ljust(25, ' ')                     # Identificação do Título na Empresa         [196..220] 25
          segmento_p << '3'                                                                # Código para Protesto                       [221..221] 01 | '1' = Protestar Dias Corridos | '2' = Protestar Dias Úteis | '3' = Não Protestar
          segmento_p << '00'                                                               # Número de Dias para Protesto               [222..223] 02
          segmento_p << '2'                                                                # Código para Baixa/Devolução                [224..224] 01 | '1' = Baixar/Devolver | '2' =  Não Baixar/Não Devolver
          segmento_p << '000'                                                              # Número de Dias para Baixa/Devolução        [225..227] 03
          segmento_p << '09'                                                               # Código da Moeda 09 REAL                    [228..229] 02
          segmento_p << ''.rjust(10, '0')                                                  # Nº do Contrato da Operação de Créd.        [230..239] 10
          segmento_p << ''.rjust(1, '0')                                                   # Uso Exclusivo FEBRABAN/CNAB                [240..240] 01
          segmento_p
        end

        # Monta o registro segmento Q do arquivo
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        #   objeto contendo os detalhes do boleto (valor, vencimento, sacado, etc)
        # @param nro_lote [Integer]
        #   numero do lote que o segmento esta inserido
        # @param sequencial [Integer]
        #   numero sequencial do registro no lote
        #
        # @return [String]
        #
        def monta_segmento_q(pagamento, nro_lote, sequencial)
          segmento_q = ''                                                                  # Descrição                         Posição    Tamanho
          segmento_q << cod_banco                                                          # Código do Banco na Compensação    [1....003] 03
          segmento_q << counter_lotes(nro_lote)                                            # Lote de Serviço                   [4....007] 04
          segmento_q << '3'                                                                # Tipo de Registro                  [8....008] 01
          segmento_q << sequencial.to_s.rjust(5, '0')                                      # Nº Sequencial do Registro no Lote [9....013] 05
          segmento_q << 'Q'                                                                # Cód. Segmento do Registro Detalhe [14...014] 01
          segmento_q << ' '                                                                # Uso Exclusivo FEBRABAN/CNAB       [15...015] 01
          segmento_q << '01'                                                               # Código de Movimento Remessa       [16...017] 02
          segmento_q << pagamento.identificacao_sacado(false)                              # Tipo de Inscrição                 [18...018] 01
          segmento_q << pagamento.documento_sacado.to_s.rjust(15, '0')                     # Número de Inscrição               [19...033] 15
          segmento_q << pagamento.nome_sacado.format_size(40)                              # Nome                              [34...073] 40
          segmento_q << pagamento.endereco_sacado.format_size(40)                          # Endereço                          [74...113] 40
          segmento_q << pagamento.bairro_sacado.format_size(15)                            # Bairro                            [114..128] 15
          segmento_q << pagamento.cep_sacado[0..4]                                         # CEP                               [129..133] 05
          segmento_q << pagamento.cep_sacado[5..7]                                         # Sufixo do CEP                     [134..136] 03
          segmento_q << pagamento.cidade_sacado.format_size(15)                            # Cidade                            [137..151] 15
          segmento_q << pagamento.uf_sacado                                                # Unidade da Federação              [152..153] 02
          segmento_q << ''.rjust(1, '0')                                                   # Tipo de Inscrição                 [154..154] 01
          segmento_q << ''.rjust(15, '0')                                                  # Número de Inscrição               [155..169] 15
          segmento_q << ''.ljust(40, ' ')                                                  # Nome do Sacador/Avalista          [170..209] 40
          segmento_q << '237'                                                              # Cód. Bco. Corresp. na Compensação [210..212] 03 | # 237 Bradesco
          segmento_q << formata_nosso_numero(pagamento.nosso_numero)                       # Nosso Nº no Banco Correspondente  [213..232] 20
          segmento_q << ''.rjust(8, ' ')                                                   # Uso Exclusivo FEBRABAN/CNAB       [233..240] 08
          segmento_q
        end

        # Monta o registro segmento S do arquivo
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        #   objeto contendo os detalhes do boleto (valor, vencimento, sacado, etc)
        # @param nro_lote [Integer]
        #   numero do lote que o segmento esta inserido
        # @param sequencial [Integer]
        #   numero sequencial do registro no lote
        #
        # @return [String]
        #
        def monta_segmento_s(pagamento, nro_lote, sequencial)
          segmento_s = ''                                                                  # Descrição                         Posição    Tamanho
          segmento_s << cod_banco                                                          # Código do Banco na Compensação    [1....003] 03
          segmento_s << counter_lotes(nro_lote)                                            # Lote de Serviço                   [4....007] 04
          segmento_s << '3'                                                                # Tipo de Registro                  [8....008] 01
          segmento_s << sequencial.to_s.rjust(5, '0')                                      # Nº Sequencial do Registro no Lote [9....013] 05
          segmento_s << 'S'                                                                # Cód. Segmento do Registro Detalhe [14...014] 01
          segmento_s << ' '                                                                # Uso Exclusivo FEBRABAN/CNAB       [15...015] 01
          segmento_s << '01'                                                               # Código de Movimento Remessa       [16...017] 02
          segmento_s << '3'                                                                # Identificação da Impressão        [18...018] 01 | 3' = Corpo de Instruções da Ficha de Compensação do Bloqueto
          segmento_s << pagamento.mensagem.format_size(200)                            # Mensagem 5                        [19...058] 40
          segmento_s << ''                                                                 # Mensagem 6                        [59...098] 40
          segmento_s << ''                                                                 # Mensagem 7                        [990..138] 40
          segmento_s << ''                                                                 # Mensagem 8                        [139..178] 40
          segmento_s << ''                                                                 # Mensagem 9                        [179..218] 40
          segmento_s << ''.rjust(22, ' ')                                                  # Uso Exclusivo FEBRABAN/CNAB       [219..240] 22
        end

        # Monta o registro trailer do lote
        #
        # @param nro_lote [Integer]
        #   numero do lote no arquivo (iterar a cada novo lote)
        #
        # @param nro_registros [Integer]
        #   numero de registros(linhas) no lote (contando header e trailer)
        #
        # @return [String]
        #
        def monta_trailer_lote(nro_lote, nro_registros)
          trailer_lote = ''                                                                # Descrição                         Posição    Tamanho
          trailer_lote << cod_banco                                                        # Código do Banco na Compensação     [1......3] 003
          trailer_lote << counter_lotes(nro_lote)                                          # Lote de Serviço                    [4......7] 004
          trailer_lote << '5'                                                              # Tipo de Registro                   [8......8] 001
          trailer_lote << ''.ljust(9, ' ')                                                 # Uso Exclusivo FEBRABAN/CNAB        [9.....17] 009
          trailer_lote << ''.rjust(6, '0')                                                 # Quantidade de Registros no Lote    [18....23] 006
          trailer_lote << ''.rjust(6, '0')                                                 # Quantidade de Títulos em Cobrança  [24....29] 006
          trailer_lote << ''.rjust(17, '0')                                                # Valor Total dosTítulos em Carteiras[30....46] 017
          trailer_lote << ''.rjust(6, '0')                                                 # Quantidade de Títulos em Cobrança  [47....52] 006
          trailer_lote << ''.rjust(17, '0')                                                # Valor Total dosTítulos em Carteiras[53....69] 017
          trailer_lote << ''.rjust(6, '0')                                                 # Quantidade de Títulos em Cobrança  [70....75] 006
          trailer_lote << ''.rjust(17, '0')                                                # Quantidade de Títulos em Carteiras [76....92] 017
          trailer_lote << ''.rjust(6, '0')                                                 # Quantidade de Títulos em Cobrança  [93....98] 006
          trailer_lote << ''.rjust(17, '0')                                                # Valor Total dosTítulos em Carteiras[99...115] 017
          trailer_lote << ''.ljust(8, ' ')                                                 # Uso exclusivo AUTBANK              [116..123] 008
          trailer_lote << ''.ljust(117, ' ')                                               # Uso Exclusivo FEBRABAN/CNAB        [124..240] 117
          trailer_lote
        end

        # Monta o registro trailer do arquivo
        #
        # @param nro_lotes [Integer]
        #   numero de lotes no arquivo
        # @param sequencial [Integer]
        #   numero de registros(linhas) no arquivo
        #
        # @return [String]
        #
        def monta_trailer_arquivo(nro_lotes, sequencia)
          trailer_arquivo = ''                                                             # Descrição                          Posição  Tamanho
          trailer_arquivo << cod_banco                                                     # Código do Banco na Compensação     [1.....3] 03
          trailer_arquivo << '9999'                                                        # Lote de Serviço                    [4.....7] 04
          trailer_arquivo << '9'                                                           # Tipo de Registro                   [8.....8] 01
          trailer_arquivo << ''.rjust(9, ' ')                                              # Uso Exclusivo FEBRABAN/CNAB        [9....17] 09
          trailer_arquivo << counter_lotes(nro_lotes, 6)                                   # Quantidade de Lotes do Arquivo     [18...23] 06
          trailer_arquivo << ''.ljust(6, '0')                                              # Quantidade de Registros do Arquivo [24...29] 06
          trailer_arquivo << ''.ljust(6, '0')                                              # Qtde de Contas p/ Conc. (Lotes)    [30...35] 06
          trailer_arquivo << ''.ljust(205, ' ')                                            # Uso Exclusivo FEBRABAN/CNAB        [36..240] 205
          trailer_arquivo
        end

        # Monta um lote para o arquivo
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        #   objeto contendo os detalhes do boleto (valor, )
        #
        # @param nro_lote [Integer]
        # numero do lote no arquivo
        #
        # @return [Array]
        #
        def monta_lote(nro_lote)
          # contador dos registros do lote
          contador = 1 # header

          lote = [monta_header_lote(nro_lote)]

          pagamentos.each do |pagamento|
            raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

            lote << monta_segmento_p(pagamento, nro_lote, contador)
            contador += 1
            lote << monta_segmento_q(pagamento, nro_lote, contador)
            contador += 1
            lote << monta_segmento_s(pagamento, nro_lote, contador)
            contador += 1
          end
          contador += 1 # trailer

          lote << monta_trailer_lote(nro_lote, contador)

          lote
        end

        # Gera o arquivo remessa
        #
        # @return [String]
        #
        def gera_arquivo
          raise Brcobranca::RemessaInvalida, self if invalid?

          arquivo = [monta_header_arquivo]

          # contador de do lotes
          contador = 1
          arquivo.push monta_lote(contador)

          arquivo << monta_trailer_arquivo(contador, ((pagamentos.size * 2) + (contador * 2) + 2))

          remittance = arquivo.join("\r\n").to_ascii.upcase
          remittance << "\r\n"

          remittance.encode(remittance.encoding, universal_newline: true).encode(remittance.encoding, crlf_newline: true)
        end
      end
    end
  end
end

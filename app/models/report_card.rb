class ReportCard < ActiveRecord::Base
  belongs_to :student
  
  def body
    Base64.decode64(self.encoded_content)
  end
  
  def name
    nc = non_custodial? ? '-nc' : ''
    "#{student_id}-#{year}-#{term}#{nc}"
  end

  class << self
    def find_card_named(name)
      m = name.match(/^([0-9]{6})-([0-9]{4})-(T[1-3])(-NC)?$/i)
      m ? find(:first,
        :conditions => ['student_id=? AND year=? AND term=? AND non_custodial=?',
          m[1].to_i, m[2], m[3].downcase, !m[4].blank?]) : nil
    end
    
    def load_bacich_report_cards(dir, year, term, non_custodial=false)
      if !year.match(/^[0-9]{4}$/) || !term.match(/^(T[1-3])$/i)
        puts "illegal year #{year} or term #{term}"
        return
      end
      Dir.glob("#{dir}/*.pdf") do |fname|
        m = fname.match(/([0-9]{6})\.pdf$/)
        if !m
          puts "cannot match #{fname}"
          next
        end
        student_number = m[1].to_i
        content = File.open(fname, 'r') { |f| f.read }
        rc = save_content(content, student_number, year.downcase, term.downcase, non_custodial)
        puts "saved #{fname} as #{rc.name}"
      end
    end

    def load_kent_report_cards(fname)
      # Generate uncompressed version tmp.pdf
      dir = nil
      if fname[0, 1] == '/'
        dir = File.dirname(fname)
        fname = File.basename(fname)
      else
        dir = File.join(Rails.root, "pdf/kent")
      end
      Dir.mkdir("#{dir}/tmp")
      system("cd #{dir}/tmp; /usr/local/bin/pdftk ../#{fname} output tmp.pdf uncompress")
      # Generate doc_data.txt and compressed pg_<nnnn>.pdf files
      system("cd #{dir}/tmp; /usr/local/bin/pdftk tmp.pdf burst")
      Dir.glob("#{dir}/tmp/pg_*.pdf") do |fname|
        # Lookup student number in pg_<nnnn>u.pdf
        content = File.open(fname, 'r') { |f| f.read }
        m = content.match(/\[([0-9]{6})-([0-9]{4})-(T[1-3])(-NC)?\]/i)
        if !m
          puts "cannot parse #{fname}"
          next
        end
        rc = save_content(content, m[1].to_i, m[2], m[3].downcase, !m[4].blank?)
        puts "saved #{fname} as #{rc.name}"
      end
      # system("cd #{dir}; rm -rf tmp")
    end

    def save_content(content, student_id, year, term, non_custodial)
      rc = find(:first,
        :conditions => ['student_id=? AND year=? AND term=? AND non_custodial=?',
          student_id, year, term, non_custodial])
      if rc
        rc.update_attribute(:encoded_content, Base64.encode64(content))
      else
        rc = ReportCard.create(
          :student_id => student_id,
          :year => year,
          :term => term,
          :non_custodial => non_custodial,
          :encoded_content => Base64.encode64(content))
      end
      rc
    end
  end
end

class HomeController < ApplicationController

  after_filter :del

  def index
    @a=0

      if params[:language]=="ruby"
        file = File.open('tmp/code.rb', 'w')
        file.syswrite(params[:code])
        file.close
        file = File.open('tmp/input.txt','w')
        file.syswrite(params[:input])
        file.close
        status = system('ruby tmp/code.rb < tmp/input.txt > tmp/result.txt')
        byebug
        if status == false
          system('ruby tmp/code.rb >& tmp/result.txt')
        end
        @result = File.read('tmp/result.txt')
        save_submission status, @result
        @a=1
      elsif params[:language]=="c"
        file = File.open('tmp/code.c', 'w')
        file.syswrite(params[:code])
        file.close
        file = File.open('tmp/input.txt','w')
        file.syswrite(params[:input])
        file.close
        status = system('gcc tmp/code.c -o tmp/code.out')
        system('./tmp/code.out < tmp/input.txt > tmp/result.txt')
        if status == false
          system('gcc tmp/code.c >& tmp/result.txt')
        end
        @result = File.read('tmp/result.txt')
        save_submission status, @result
        @a = 1
      end
    render 'index'
  end

  

  def run_ruby
    file = File.open('tmp/code.rb', 'w')
    file.syswrite(params[:code])
    file.close
    system('ruby tmp/code.rb > tmp/result.txt')
    @result = File.read('tmp/result.txt')
    @a=1
    render 'index'
  end

  def run
    lang = params[:lang]
    source_code = params[:source]
    input = params[:input]
    evaluate(lang, source_code, input)
  end

  def evaluate(lang, source, input)
    if lang == "CPP"
      evaluate_cpp(lang, source, input)
    elsif lang == "RUBY"
      evaluate_ruby(lang, source, input)
    elsif lang == "PYTHON"
      evaluate_ruby(lang, source, input)
    elsif lang == "JAVA"
      evaluate_java(lang, source, input)
    elsif lang == "C"
      evaluate_c(lang, source, input)
    end
  end

  def evaluate_c(lang, source, input)
    file = File.open('tmp/code.c', 'w')
    file.syswrite(source)
    file.close
    file = File.open('tmp/input.txt','w')
    file.syswrite(input)
    file.close
    compile_status = system('gcc tmp/code.c -o tmp/code.out >& tmp/result.txt')
    file = File.open('tmp/result.txt','r')
    if compile_status == false
      return render json: {
      :compile_status => "NOTOK",
      :logs => file.read
    }
    else
      status = system('gtimeout 4 bash -c "./tmp/code.out < tmp/input.txt >& tmp/result.txt"; echo $? >& tmp/timeout_status.txt')
      file = File.open("tmp/timeout_status.txt", 'r')
      byebug
      if file.read.to_i == 124
        file.close()
        return render json: {
          :compile_status => "OK",
          :run_status => {
          :status => "TLE"
          }
        }
      elsif file.read.to_i == 1
        file.close()
        error = File.open("tmp/result.txt", 'r');
        error_c = error.read
        error.close()
        return render json: {
          :compile_status => "OK",
          :run_status => {
          :status => "NOTOK",
          :stderr => error_c
          }
        }
      elsif file.read.to_i == 0
        file.close();
        result = File.open("tmp/result.txt", 'r')
        result_c = result.read
        return render json: {
          :compile_status => "OK",
          :run_status => {
          :status => "AC",
          :output_html => result_c
          }
        }
      else
        render json: {
          :status => "OK",
          :run_status => {
            :status => "NOTOK",
            :stderr => "Stack Error"
          }
        }
      end
    end
  end



  def del 
    if params[:lang]=="ruby"
      File.delete('tmp/code.rb')
      File.delete('tmp/result.txt')
    elsif params[:lang]=="c"
      File.delete('tmp/code.c')
      File.delete('tmp/result.txt')
    end
    
  end

  def save_submission status , result
    language_validation = UserSubmission.validates_language_params params[:language]
    user_submission = UserSubmission.new
    user_submission.user_id = current_user.id
    user_submission.language = params[:language]
    user_submission.extension = (UserSubmission.languages.values_at user_submission.language)[0]
    user_submission.code = params[:code]
    user_submission.input = params[:input]
    user_submission.success = status
    user_submission.output = result
    user_submission.save
  end

end

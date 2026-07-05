import Foundation

protocol CaptionServing { func caption(for month: MonthInterval, photoCount: Int, variant: Int) -> String }

struct LocalCaptionService: CaptionServing {
    func caption(for month: MonthInterval, photoCount: Int, variant: Int = 0) -> String {
        let monthName = month.start.formatted(.dateTime.month(.wide).locale(Locale(identifier: "pt_BR"))).capitalized
        let options = [
            "\(monthName) foi feito de momentos que mereciam ficar. Entre dias corridos, encontros e pequenas pausas, escolhi \(photoCount) lembranças para contar um pouco dessa história. Que venha o próximo capítulo. ✨",
            "Um mês inteiro em \(photoCount) lembranças. \(monthName) trouxe movimento, presença e histórias boas demais para ficarem só no rolo da câmera. 🤍",
            "\(monthName), do jeito que eu quero lembrar: gente querida, caminhos percorridos e os detalhes que fizeram tudo valer a pena. 📸"
        ]
        return options[variant % options.count]
    }
}
